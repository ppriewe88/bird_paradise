USE [ProjektarbeitPP]
GO

/****** Object:  StoredProcedure [dbo].[spDefineOrderStatusAndProcessIfCommissioned]    Script Date: 10.10.2024 14:16:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE  OR ALTER   PROCEDURE [dbo].[spDefineOrderStatusAndProcessIfCommissioned]

----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Diese Prozedur wird aufgerufen, wenn
		- eine Bestellung (order) über Insert angelegt wird, und der entsprechende AFTER-INSERT-Trigger an der orders-Tabelle ausgelöst wird.
		- eine Bestellung über die Prozedur spCreateNewOrder angelegt wird (was ebenfalls den obigen Trigger auslöst).
		- die Prozedur spCheckExistingOrderForCommission für eine Bestellung aufgerufen wird.
	Die Prozedur tut folgendes:
		- Schaue dir alle Produktbestände an (inventories) zu dem zu bestellenden Produkt. 
			- Wenn mindestens einer der Bestände (inventories) größergleich der zu bestellenden Menge (quantity) ist, ist die Bestellung LIEFERBAR, andernfalls NICHT.
			- Falls Lieferung möglich, 
				- setze Bestellung auf "beauftragt" (Status 1) an
				- reduziere den Bestand (inventories) im gefundenen Lager
				- erzeuge eine Rechnung (über Prozeduraufruf) im Status "unpaid"
			- Falls Lieferung nicht möglich,
				- reduziere nirgends Bestand, erzeuge keine Rechnung
				- setze Bestellung auf "abgelehnt" (Status 3)
*/

--------------- Übergebene Variablen aus zu prüfender Bestellung
			@orderID INT,
			@customerID INT,
			@ProductID BIGINT, 
			@OrderQuantity INT,
			@statusID INT,
			@created_at DATETIME  -- Hinweis: wird nur durchgereicht und NIRGENDS für orders verwendet. Dient NUR zur Weiterreichung in spCreateInvoiceOnOrder, wo die Rechnung mit diesem Zeitstempel erstellt wird!
				

AS
BEGIN


---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;

--------------------------------------------------------------------------------------- BESTANDSPRÜFUNG, SATUSDEFINITION, LAGERREDUKTION, RECHNUNGSANLAGE: Start	
		
		---- Variablendeklaration prozedurinterne Variablen
		DECLARE @CurrentStock INT;
		DECLARE @storageLocation INT;
		DECLARE @deliveryfrom INT;
		DECLARE @numberOfStorageLocations INT;   
		-----------------------------------------------------------	BEGINNE BESTANDSPRÜFUNG: Prüfen, ob eines der Lager genug Bestand für Lieferung hat.

		SET @storageLocation = 1;																-- Zähler für zu prüfende Lager; Start bei 1
		SET @numberOfStorageLocations = (SELECT COUNT(*) FROM inventory_storagelocations);		-- Anzahl der Lager, als Obergrenze für Schleife
		SET @deliveryfrom = 0;																	-- Outputvariable, um das Lager auszugeben, aus dem geliefert werden kann.
		
		PRINT (CHAR(13) + CHAR(10) + 'Prozedur spDefineOrderStatusAndProcessIfCommissioned Durchlauf gestartet')

		-- WHILE-Schleife um durch die Lager zu iterieren. Bei Lager 1 anfangen (@storageLocation = 1), Lager für Lager durchgehen
		WHILE @storageLocation <= @numberOfStorageLocations								-- Lager durchiterieren			  
		BEGIN
		
			-- Bestand des Produkts in gewähltem Lager holen
			SELECT @CurrentStock = stock
			FROM dbo.inventory
			WHERE product_id = @ProductId AND storage_location_id = @storageLocation;
		
			-- Wenn genügend Lagerbestand vorhanden ist, breche die Schleife ab
			IF @OrderQuantity <= @CurrentStock
			BEGIN
				-- merke dir das Lager, aus dem geliefert werden kann
				SET @deliveryfrom = @storageLocation;
				-- Beende die Schleife, da ein Lager mit genügend Bestand gefunden haben
				BREAK;
			END

			-- Gehe zum nächsten Lager
			SET @storageLocation = @storageLocation + 1;
		END	

		------- Ergebnis bis hierhin: Lager, aus dem geliefert werden kann, wurde ermittelt und in @deliveryfrom gespeichert!


		PRINT (CHAR(13) + CHAR(10) + 'Bestandsprüfung und Lagerauswahl wurde durchlaufen' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 'HINWEIS: Auftrag (=Bestellung) wurde angelegt!' + CHAR(13) + CHAR(10))

		------------------------------------------------------------- ENDE BESTANDSPRÜFUNG
		------------------------------------------------------------- START FALLBEHANDLUNG
		---------------------------------------------------------	FALL 1.1: aus keinem Lager kann geliefert werden (@deliveryfrom_as_output = 0)!
		IF
			@deliveryfrom = 0		-- wenn oben kein Lager gefunden wurde
			BEGIN
				-- Lagerbestand des Produkts NICHT anpassen (Kunde wird NICHT beliefert!)
	
				-- angelegte order wird auf "abgelehnt" (harter Statuseintrag 3 aus orders_status) gesetzt!
				UPDATE dbo.orders 
				SET status_id = 3
				WHERE id = @orderID
				
				-- Ausgeben, dass nicht geliefert werden kann
				PRINT (CHAR(13) + CHAR(10) + 'HINWEIS: Bestellung ' + CAST(@orderID AS nvarchar(10)) +  ' kann nicht geliefert werden! In keinem Lager genügend Bestand verfügbar.' + CHAR(13) + CHAR(10) + 'Antrag ist/bleibt im Status "abgelehnt".' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 'HINWEIS: Es wurde folglich KEINE Rechnung angelegt!');

				-- KEINE Rechnung wird erstellt

			END

		---------------------------------------------------------	FALL 1.2: es kann geliefert werden (@deliveryfrom_as_output > 0)
		ELSE
			BEGIN
			
				-- Lagerbestand reduzieren
				PRINT 'Lagerbestand wurde reduziert'
				UPDATE dbo.inventory
				SET stock = stock - @OrderQuantity
				WHERE product_id = @ProductID AND storage_location_id = @storageLocation;
				
				-- order wird auf "beauftragt" (harter Statuseintrag 1 aus orders_status) gesetzt.
				UPDATE dbo.orders 
				SET status_id = 1
				WHERE id = @orderID
				
				-- Ausgeben, dass geliefert werden kann
				PRINT (CHAR(13) + CHAR(10) + 'In Prozedur: Bestellung ' + CAST(@orderID AS nvarchar(10)) +  ' kann aus Lager ' + CAST(@deliveryfrom AS VARCHAR) + ' erfüllt werden. Antrag mit "beauftragt" angelegt.');

				
				-- Rechnungserstellung über Prozedur spCreateInvoiceOnOrder:
				PRINT (CHAR(13) + CHAR(10) + 'Nun wird die zugehörige Rechnung erzeugt. Springe dazu in Prozedur spCreateInvoiceOnOrder.')
				EXEC spCreateInvoiceOnOrder @order_id_for_invoice = @orderID, @created_at_for_invoice = @created_at
				PRINT (CHAR(13) + CHAR(10) + 'Rechnung wurde erzeugt. Zurückgekehrt aus Prozedur spCreateInvoiceOnOrder.')
			
			END;

		PRINT (CHAR(13) + CHAR(10) + 'Prozedur spDefineOrderStatusAndProcessIfCommissioned Durchlauf beendet')
---------------------------------------------------------------------------------------------------- BESTANDSPRÜFUNG, SATUSDEFINITION, LAGERREDUKTION, RECHNUNGSANLAGE: Ende

-------------- Erfolgreiche Ausführung, commit der Transaktion
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



END
GO


