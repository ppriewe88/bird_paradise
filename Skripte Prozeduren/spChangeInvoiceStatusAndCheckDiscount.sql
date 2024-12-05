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
	Nimmt Rechnung, nimmt eingespeisten Zielstatus, in den �berf�hrt werden soll, und schaut, was bei Statuswechsel gemacht werden muss.
	-- Dabei wird sorgf�ltig gepr�ft, in welchem Status die Rechnung beim EIngang in die Prozedur aktuell ist, und was dann gemacht werden darf:
		-- wenn mit status 2 = paid ankommend:
			-- HIER DARF NICHTS GEMACHT WERDEN! Wir wollen nicht, dass bezahlte Rechnungen wieder zur�ckgesetzt werden, da inkonsistente Zust�nde entstehen!
		-- wenn mit status 1 = unpaid ankommend:
			-- Falls gew�nschter Zielstatus 1 = unpaid ODER 3 = overdue ist: 
				--	pr�fe Sicherheit, ob Zahltag verstrichen. Falls ja, wechsle auf status 3=overdue und setze Mahngeb�hr (overdue_fee), falls nein gehe auf status 1=unpaid und setze Mahngeb�hr (overdue_fee) auf 0.
			-- Falls gew�nschter Zielstatus 2 = paid ist: 
				--	passt, setze den status
		-- wenn mit Status 3 = overdue ankommend:
			-- Falls gew�nschter Zielstatus 1 = unpaid ODER 3 = overdue ist: 
				--	pr�fe Sicherheit, ob Zahltag verstrichen. Falls ja, wechsle auf status 3=overdue und setze Mahngeb�hr (overdue_fee), falls nein gehe auf status 1=unpaid und setze Mahngeb�hr (overdue_fee) auf 0.
			-- Falls gew�nschter Zielstatus 2 = paid ist: 
				--	passt, setze den status
	-- Pr�fe im Anschluss in jedem Fall die Rabatteigenschaft des Kunden: 
		-- Wenn Kunde in Vergangenheit in allen paid-Rechnungen in Summe einen Umsatz von mehr als "required_revenue_for_discount" (hinterlegt als Referenzwert in tabelle commercial_parameters) erzielt hat, hinterlege beim Kunden die "discount_rate" aus den commercial_parameters. Dann bekommt er zuk�nftig Rabatt auf Rechnungen!

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
	---Variablendeklaration f�r Vergleich �nderung Feld status_id durch UPDATE
    DECLARE @currentStatusID INT;
	---Variablen f�r Abgleich Kundenumsatz gegen Rabattierungsgrenze
	DECLARE @customerRevenue DECIMAL(10,2);
	DECLARE @requiredCustomerRevenue DECIMAL(10,2);
	-- Variable f�r Rabattrate aus commercial_parameters-Tabelle
	DECLARE @discount_rate INT;
	-- Variable f�r Mahnungsprozentsatz (overdue_fee_percentage) aus commercial_parametersTabelle
	DECLARE @overdue_fee_percentage INT;


---------------------------------------------------------- Eingabeparameter �berpr�fen
	--- G�ltigkeit Rechnungs-ID checken
	IF EXISTS (SELECT 1 FROM invoices WHERE id = @invoiceID)
		BEGIN
			PRINT 'ID gefunden';
		END
	ELSE 
		RAISERROR ('Rechnungs-ID nicht gefunden! B�ser Benutzer! Hast du etwa eine ung�ltige Rechnungs-ID angegeben, oder vergessen, sie anzugeben??', 16, 1)
	--- G�ltigkeit status-id checken
	IF EXISTS (SELECT 1 FROM invoices_status WHERE id = @newStatusID)
		BEGIN
			PRINT 'Status gefunden';
		END
	ELSE 
		RAISERROR ('Status-ID nicht gefunden! B�ser Benutzer! Hast du etwa eine ung�ltige Status-ID angegeben, oder vergessen, sie anzugeben??', 16, 1)

---------------------------------------------------------- Order-ID der zugeh. Bestellung holen (wird f�r statuswechsel auf "paid" ben�tigt und f�r Rabattpr�fung am Ende)
--- Order-ID der zugeh�rigen Bestellung ermitteln
			SELECT @OrderID = order_id 
			FROM invoices
			WHERE id = @invoiceID

----------------------------------------------------------gew�nschte Status�nderung checken
	-- Alten und neuen Status der ge�nderten Rechnung holen
    PRINT 'gew�nschter Status: ' + CAST(@newStatusID AS nvarchar(10))
	
	SELECT @currentStatusID = inv.status_id
    FROM invoices inv
	WHERE inv.id = @invoiceID
    
	PRINT 'bisheriger Status: ' + CAST(@currentStatusID AS nvarchar(10))

IF @currentStatusID = 2 -- status 2 hei�t, Rechnungs ist bereits bezahlt. Hier wird nichts getan, wir wollen keine bezahlten Rechnungen zur�cksetzen!!
	PRINT 'Die Rechnung ist im Status "paid". Diese Prozedur unterst�tzt keinen Statuswechsel f�r Rechnungen, die bereits bezahlt sind!' + CHAR(13) + CHAR(10) + 'Begr�ndung: Es k�nnte passieren, dass eine Rechnung von paid auf unpaid (oder auch overdue) gesetzt wird, was im kommerziellen Betrieb ein Einzelfall sein sollte.' + CHAR(13) + CHAR(10) + 'Dann k�me zustande, dass eine Rechnung mit "unpaid" existiert, aber daf�r eine Bestellung mit Status "geliefert" vorliegt, was vermieden werden sollte.' + CHAR(13) + CHAR(10) + 'Entsprechend ist der Statuswechsel auf "unpaid" von fachkundigem Personal manuell zu unternehmen.' + CHAR(13) + CHAR(10) + 'Dabei sind orders zu ber�cksichtigen, und die Rabatteigenschaft des Kunden zu pr�fen (discount).' + CHAR(13) + CHAR(10) + 'Das einzige, was hier noch vorgenommen wird, ist die Rabatteigenschaft des Kunden erneut zu pr�fen.'
	-- nichts weiter tun
	ELSE 
		BEGIN ------------ bei ELSE-F�llen kommen wir hier mit status 1=unpaid oder 3= overdue an. Egal von wo wir kommen, wir gehen auf unpaid oder overdue, je nachdem was zutrifft!
			-----------Wenn auf "unpaid" (=1) oder "overdue (=3) gewechselt werden soll (von unpaid oder overdue kommend):------------------------------------------
			IF @newStatusID = 1 OR @newStatusID = 3
				BEGIN -- pr�fe ob Zahltag verstrichen. Falls ja, setze status 3 = overdue und Mahngeb�hr (overdue_fee), Falls nein, setze status 1 = unpaid und entferne Mahngeb�hr (overdue_fee)
					PRINT 'Status�nderung (von unpaid oder overdue) nach unpaid gew�nscht. Overdue_Eigenschaft wird �berpr�ft. Falls nicht overdue, resultiert Status auf 1=unpaid gewechselt und etwaiger overdue_fee wird entfernt.'
					--overdue_Eigenschaft �berpr�fen
						-- �berpr�fung, ob due_date in der Vergangenheit liegt. Falls ja, Status�nderung vornehmen und overdue_fee entfernen, falls nein, nichts tun
							IF (SELECT due_date FROM invoices WHERE id = @invoiceID) < getdate()  --overdue-Pr�fung
								BEGIN -- Overdue_fee ermitteln und setzen
									PRINT 'Zahltag liegt in der Vergangenheit, Rechnung ist also overdue. Resultierender Status ist 3 = overdue, mit overdue_fee!';
									-- overdue_fee_percentage heranziehen
										SELECT	@overdue_fee_percentage = value_integer
										FROM	dbo.commercial_parameters
										WHERE	id = 2;						-- da steht overdue_fee_percentage drin!
										PRINT CAST(@overdue_fee_percentage AS nvarchar(80))
									-- overdue_fee mithilfe von overdue_fee_percentage berechnen, status �ndern
										UPDATE	invoices
										SET		overdue_fee = @overdue_fee_percentage * total_price / 100,		-- overdue percentage wird an Gesamtpreis ranmultipliziert
												status_id = 3 --overdue setzen!
										WHERE	id = @invoiceID
								END
							ELSE
								BEGIN -- Rechnung ist nicht overdue!
									PRINT 'Zahltag noch nicht �berschritten, Status also 1=unpaid. Kein overdue_fee.';
									--- auf unpaid setzen
									UPDATE invoices
									SET status_id = 1, overdue_fee = 0 -- Status 1 = unpaid
									WHERE id = @invoiceID
								END
				END
	
			
			----------- Wenn auf "paid" (=2) gewechselt wird (von unpaid oder overdue kommend): ----------------------------------------------------------------------------
			IF @newStatusID = 2
				BEGIN -- zugeh�rige Bestellung auf geliefert setzen, Rechnung auf paid setzen
					PRINT 'Status�nderung auf paid gew�nscht.'

					--- zugeh�rige Bestellung auf geliefert (=2) setzen
					UPDATE orders
					SET status_id = 2
					WHERE id = @OrderID
					PRINT 'Zugeh�rige Bestellung mit order_id = ' + CAST(@OrderID AS nvarchar(10)) + ' wurde abgeschlossen (geliefert).'

					--- Rechnung auf paid (=2) setzen
					UPDATE invoices
					SET status_id = 2
					WHERE id = @invoiceID
					PRINT 'Rechnung mit id = ' + CAST(@invoiceID AS nvarchar(10)) + ' wurde abgeschlossen (paid).'		
				END
		END
-------------------------------Einzelfallbehandlung oben ist abgeschlossen. Nun noch die Rabatteigenschaftspr�fung f�r den Kunden durchf�hren (pr�fen, ob Kunde bereits bestimmten Umsatzwert historisch gezahlt hat; falls ja, dann bekommt er Rabatt:

			--- Kunden-ID der zugeh�rigen Bestellung ermitteln
				SELECT @CustomerID = customer_id 
				FROM orders
				WHERE id = @OrderID
				

			--- Rabattrate und ben�tigten Mindestumsatz f�r Rabatt aus commercial_parameters holen
				SELECT @discount_rate = value_integer
				FROM dbo.commercial_parameters
				WHERE id = 4	-- hei�t dort discount_rate dort ist die Rabattrate hinterlegt, die man als rabbatierter Kunde bekommt
				

				SELECT @requiredCustomerRevenue = value_integer
				FROM dbo.commercial_parameters
				WHERE id = 3	-- hei�t dort required_revenue_for_discount; ist der Umsatz, den ein Kunde gezahlt haben muss (Summe �ber bez. Rechnungen) um zuk�nftig Rabatt zu erhalten.
				

			--- pr�fen, ob Kunde Rabattregel erf�llt: Mehr als XXX Euro in bezahlten Rechnungen?
				-- bezahlte Kundenums�tze aufsummieren und zwischenspeichern
				SELECT		@customerRevenue = SUM(i.total_price_discounted) 
				FROM		invoices i
				JOIN		orders o
				ON			i.order_id = o.id
				WHERE		o.customer_id = @CustomerID AND i.status_id = 2  -- status 2 hier ist "paid" bei Rechnungen


				IF @customerRevenue > @requiredCustomerRevenue		-- hat Kunde bereits mehr als den n�tigen Gesamtumsatz historisch gemacht? Dann kriegt er Rabatt
					BEGIN
						UPDATE	customers
						SET		discount = @discount_rate	--Kunde kriegt also Rabattwert zuk�nftig!
						WHERE	id = @CustomerID
						PRINT 'Kunde hat in seiner Historie in Summe ' + CAST(@customerRevenue AS nvarchar(20)) + ' Euro Umsatz gebracht (bezahlte Rechnungen), also mehr als ' + CAST(@requiredCustomerRevenue AS nvarchar(80)) + '. Er erh�lt also zuk�nftig ' + CAST(@discount_rate AS nvarchar(80)) + ' Prozent Rabatt'
					END
				ELSE 
					BEGIN
						UPDATE	customers
						SET		discount = 0	--Kunde bekommt keinen Rabatt!!
						WHERE	id = @CustomerID
						PRINT 'Der Kunde hat nicht gen�gend Ums�tze in bezahlten Rechnungen erbracht, um Rabattkunde zu sein! Der Rabattwert wurde (ggf. wieder zur�ck) auf 0 gesetzt. Beachten Sie: Rechnungen des Kunden, die in der Vergangenheit mit rabattiertem Gesamtpreis entstanden sind (und evt. noch offen sind) wurden NICHT ver�ndert!'
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


