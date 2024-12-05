USE [ProjektarbeitPP]
GO

/****** Object:  StoredProcedure [dbo].[spChangeInvoiceStatusAndCheckDiscount]    Script Date: 10.10.2024 16:35:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE OR ALTER      PROCEDURE [dbo].[spChangeInvoiceStatusAndCheckDiscount]

----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Nimmt Rechnung, nimmt eingespeisten Zielstatus, in den überführt werden soll, und schaut, was bei Statuswechsel gemacht werden muss.
	-- Dabei wird sorgfältig geprüft, in welchem Status die Rechnung beim EIngang in die Prozedur aktuell ist, und was dann gemacht werden darf:
		-- wenn mit status 2 = paid ankommend:
			-- HIER DARF NICHTS GEMACHT WERDEN! Wir wollen nicht, dass bezahlte Rechnungen wieder zurückgesetzt werden, da inkonsistente Zustände entstehen!
		-- wenn mit status 1 = unpaid ankommend:
			-- Falls gewünschter Zielstatus 1 = unpaid ODER 3 = overdue ist: 
				--	prüfe Sicherheit, ob Zahltag verstrichen. Falls ja, wechsle auf status 3=overdue und setze Mahngebühr (overdue_fee), falls nein gehe auf status 1=unpaid und setze Mahngebühr (overdue_fee) auf 0.
			-- Falls gewünschter Zielstatus 2 = paid ist: 
				--	passt, setze den status
		-- wenn mit Status 3 = overdue ankommend:
			-- Falls gewünschter Zielstatus 1 = unpaid ODER 3 = overdue ist: 
				--	prüfe Sicherheit, ob Zahltag verstrichen. Falls ja, wechsle auf status 3=overdue und setze Mahngebühr (overdue_fee), falls nein gehe auf status 1=unpaid und setze Mahngebühr (overdue_fee) auf 0.
			-- Falls gewünschter Zielstatus 2 = paid ist: 
				--	passt, setze den status
	-- Prüfe im Anschluss in jedem Fall die Rabatteigenschaft des Kunden: 
		-- Wenn Kunde in Vergangenheit in allen paid-Rechnungen in Summe einen Umsatz von mehr als "required_revenue_for_discount" (hinterlegt als Referenzwert in tabelle commercial_parameters) erzielt hat, hinterlege beim Kunden die "discount_rate" aus den commercial_parameters. Dann bekommt er zukünftig Rabatt auf Rechnungen!

*/
			@invoiceID INT,
			@newStatusID INT

AS
BEGIN

---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;


----------------------------------------------------------Variablendeklaration
	-- Order-ID Variable und Customer-ID
	DECLARE @OrderID INT;
	DECLARE @CustomerID INT;
	---Variablendeklaration für Vergleich Änderung Feld status_id durch UPDATE
    DECLARE @currentStatusID INT;
	---Variablen für Abgleich Kundenumsatz gegen Rabattierungsgrenze
	DECLARE @customerRevenue DECIMAL(10,2);
	DECLARE @requiredCustomerRevenue DECIMAL(10,2);
	-- Variable für Rabattrate aus commercial_parameters-Tabelle
	DECLARE @discount_rate INT;
	-- Variable für Mahnungsprozentsatz (overdue_fee_percentage) aus commercial_parametersTabelle
	DECLARE @overdue_fee_percentage INT;


---------------------------------------------------------- Eingabeparameter überprüfen
	--- Gültigkeit Rechnungs-ID checken
	IF EXISTS (SELECT 1 FROM invoices WHERE id = @invoiceID)
		BEGIN
			PRINT 'ID gefunden';
		END
	ELSE 
		RAISERROR ('Rechnungs-ID nicht gefunden! Böser Benutzer! Hast du etwa eine ungültige Rechnungs-ID angegeben, oder vergessen, sie anzugeben??', 16, 1)
	--- Gültigkeit status-id checken
	IF EXISTS (SELECT 1 FROM invoices_status WHERE id = @newStatusID)
		BEGIN
			PRINT 'Status gefunden';
		END
	ELSE 
		RAISERROR ('Status-ID nicht gefunden! Böser Benutzer! Hast du etwa eine ungültige Status-ID angegeben, oder vergessen, sie anzugeben??', 16, 1)

---------------------------------------------------------- Order-ID der zugeh. Bestellung holen (wird für statuswechsel auf "paid" benötigt und für Rabattprüfung am Ende)
--- Order-ID der zugehörigen Bestellung ermitteln
			SELECT @OrderID = order_id 
			FROM invoices
			WHERE id = @invoiceID

----------------------------------------------------------gewünschte Statusänderung checken
	-- Alten und neuen Status der geänderten Rechnung holen
    PRINT 'gewünschter Status: ' + CAST(@newStatusID AS nvarchar(10))
	
	SELECT @currentStatusID = inv.status_id
    FROM invoices inv
	WHERE inv.id = @invoiceID
    
	PRINT 'bisheriger Status: ' + CAST(@currentStatusID AS nvarchar(10))

IF @currentStatusID = 2 -- status 2 heißt, Rechnungs ist bereits bezahlt. Hier wird nichts getan, wir wollen keine bezahlten Rechnungen zurücksetzen!!
	PRINT 'Die Rechnung ist im Status "paid". Diese Prozedur unterstützt keinen Statuswechsel für Rechnungen, die bereits bezahlt sind!' + CHAR(13) + CHAR(10) + 'Begründung: Es könnte passieren, dass eine Rechnung von paid auf unpaid (oder auch overdue) gesetzt wird, was im kommerziellen Betrieb ein Einzelfall sein sollte.' + CHAR(13) + CHAR(10) + 'Dann käme zustande, dass eine Rechnung mit "unpaid" existiert, aber dafür eine Bestellung mit Status "geliefert" vorliegt, was vermieden werden sollte.' + CHAR(13) + CHAR(10) + 'Entsprechend ist der Statuswechsel auf "unpaid" von fachkundigem Personal manuell zu unternehmen.' + CHAR(13) + CHAR(10) + 'Dabei sind orders zu berücksichtigen, und die Rabatteigenschaft des Kunden zu prüfen (discount).' + CHAR(13) + CHAR(10) + 'Das einzige, was hier noch vorgenommen wird, ist die Rabatteigenschaft des Kunden erneut zu prüfen.'
	-- nichts weiter tun
	ELSE 
		BEGIN ------------ bei ELSE-Fällen kommen wir hier mit status 1=unpaid oder 3= overdue an. Egal von wo wir kommen, wir gehen auf unpaid oder overdue, je nachdem was zutrifft!
			-----------Wenn auf "unpaid" (=1) oder "overdue (=3) gewechselt werden soll (von unpaid oder overdue kommend):------------------------------------------
			IF @newStatusID = 1 OR @newStatusID = 3
				BEGIN -- prüfe ob Zahltag verstrichen. Falls ja, setze status 3 = overdue und Mahngebühr (overdue_fee), Falls nein, setze status 1 = unpaid und entferne Mahngebühr (overdue_fee)
					PRINT 'Statusänderung (von unpaid oder overdue) nach unpaid gewünscht. Overdue_Eigenschaft wird überprüft. Falls nicht overdue, resultiert Status auf 1=unpaid gewechselt und etwaiger overdue_fee wird entfernt.'
					--overdue_Eigenschaft überprüfen
						-- Überprüfung, ob due_date in der Vergangenheit liegt. Falls ja, Statusänderung vornehmen und overdue_fee entfernen, falls nein, nichts tun
							IF (SELECT due_date FROM invoices WHERE id = @invoiceID) < getdate()  --overdue-Prüfung
								BEGIN -- Overdue_fee ermitteln und setzen
									PRINT 'Zahltag liegt in der Vergangenheit, Rechnung ist also overdue. Resultierender Status ist 3 = overdue, mit overdue_fee!';
									-- overdue_fee_percentage heranziehen
										SELECT	@overdue_fee_percentage = value_integer
										FROM	dbo.commercial_parameters
										WHERE	id = 2;						-- da steht overdue_fee_percentage drin!
										PRINT CAST(@overdue_fee_percentage AS nvarchar(80))
									-- overdue_fee mithilfe von overdue_fee_percentage berechnen, status ändern
										UPDATE	invoices
										SET		overdue_fee = @overdue_fee_percentage * total_price / 100,		-- overdue percentage wird an Gesamtpreis ranmultipliziert
												status_id = 3 --overdue setzen!
										WHERE	id = @invoiceID
								END
							ELSE
								BEGIN -- Rechnung ist nicht overdue!
									PRINT 'Zahltag noch nicht überschritten, Status also 1=unpaid. Kein overdue_fee.';
									--- auf unpaid setzen
									UPDATE invoices
									SET status_id = 1, overdue_fee = 0 -- Status 1 = unpaid
									WHERE id = @invoiceID
								END
				END
	
			
			----------- Wenn auf "paid" (=2) gewechselt wird (von unpaid oder overdue kommend): ----------------------------------------------------------------------------
			IF @newStatusID = 2
				BEGIN -- zugehörige Bestellung auf geliefert setzen, Rechnung auf paid setzen
					PRINT 'Statusänderung auf paid gewünscht.'

					--- zugehörige Bestellung auf geliefert (=2) setzen
					UPDATE orders
					SET status_id = 2
					WHERE id = @OrderID
					PRINT 'Zugehörige Bestellung mit order_id = ' + CAST(@OrderID AS nvarchar(10)) + ' wurde abgeschlossen (geliefert).'

					--- Rechnung auf paid (=2) setzen
					UPDATE invoices
					SET status_id = 2
					WHERE id = @invoiceID
					PRINT 'Rechnung mit id = ' + CAST(@invoiceID AS nvarchar(10)) + ' wurde abgeschlossen (paid).'		
				END
		END
-------------------------------Einzelfallbehandlung oben ist abgeschlossen. Nun noch die Rabatteigenschaftsprüfung für den Kunden durchführen (prüfen, ob Kunde bereits bestimmten Umsatzwert historisch gezahlt hat; falls ja, dann bekommt er Rabatt:

			--- Kunden-ID der zugehörigen Bestellung ermitteln
				SELECT @CustomerID = customer_id 
				FROM orders
				WHERE id = @OrderID
				

			--- Rabattrate und benötigten Mindestumsatz für Rabatt aus commercial_parameters holen
				SELECT @discount_rate = value_integer
				FROM dbo.commercial_parameters
				WHERE id = 4	-- heißt dort discount_rate dort ist die Rabattrate hinterlegt, die man als rabbatierter Kunde bekommt
				

				SELECT @requiredCustomerRevenue = value_integer
				FROM dbo.commercial_parameters
				WHERE id = 3	-- heißt dort required_revenue_for_discount; ist der Umsatz, den ein Kunde gezahlt haben muss (Summe über bez. Rechnungen) um zukünftig Rabatt zu erhalten.
				

			--- prüfen, ob Kunde Rabattregel erfüllt: Mehr als XXX Euro in bezahlten Rechnungen?
				-- bezahlte Kundenumsätze aufsummieren und zwischenspeichern
				SELECT		@customerRevenue = SUM(i.total_price_discounted) 
				FROM		invoices i
				JOIN		orders o
				ON			i.order_id = o.id
				WHERE		o.customer_id = @CustomerID AND i.status_id = 2  -- status 2 hier ist "paid" bei Rechnungen


				IF @customerRevenue > @requiredCustomerRevenue		-- hat Kunde bereits mehr als den nötigen Gesamtumsatz historisch gemacht? Dann kriegt er Rabatt
					BEGIN
						UPDATE	customers
						SET		discount = @discount_rate	--Kunde kriegt also Rabattwert zukünftig!
						WHERE	id = @CustomerID
						PRINT 'Kunde hat in seiner Historie in Summe ' + CAST(@customerRevenue AS nvarchar(20)) + ' Euro Umsatz gebracht (bezahlte Rechnungen), also mehr als ' + CAST(@requiredCustomerRevenue AS nvarchar(80)) + '. Er erhält also zukünftig ' + CAST(@discount_rate AS nvarchar(80)) + ' Prozent Rabatt'
					END
				ELSE 
					BEGIN
						UPDATE	customers
						SET		discount = 0	--Kunde bekommt keinen Rabatt!!
						WHERE	id = @CustomerID
						PRINT 'Der Kunde hat nicht genügend Umsätze in bezahlten Rechnungen erbracht, um Rabattkunde zu sein! Der Rabattwert wurde (ggf. wieder zurück) auf 0 gesetzt. Beachten Sie: Rechnungen des Kunden, die in der Vergangenheit mit rabattiertem Gesamtpreis entstanden sind (und evt. noch offen sind) wurden NICHT verändert!'
					END

COMMIT TRANSACTION;
END TRY

---------------Catch-Block
BEGIN CATCH
			
	-- Bei Fehler Rollback der Transaktion
	ROLLBACK TRANSACTION;

	-- Fehlerdetails erfassen
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorLine INT;
    DECLARE @ErrorProcedure NVARCHAR(200);

    -- Werte aus der Fehlerbehandlungsfunktion abrufen
    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorNumber = ERROR_NUMBER(),
        @ErrorLine = ERROR_LINE(),
        @ErrorProcedure = ERROR_PROCEDURE();

    -- Fehlerausgabe
    RAISERROR(
        'Fehlernummer: %d, Fehlerprozedur: %s, Fehlerzeile: %d, Fehler: %s. ',
        @ErrorSeverity, @ErrorState, 
        @ErrorNumber, @ErrorProcedure, @ErrorLine, @ErrorMessage
    );
END CATCH


END;

GO


