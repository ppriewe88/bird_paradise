USE [ProjektarbeitPP]
GO

/****** Object:  Trigger [dbo].[trgWhenInsertingOrderDoStuff]    Script Date: 10.10.2024 13:27:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE  OR ALTER TRIGGER [dbo].[trgWhenInsertingOrderDoStuff]
ON [dbo].[orders]

AFTER INSERT ---------------legt die Eigenschaft fest, dass nach Insert ausgeführt wird!!


----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Nimmt INSERT-Werte für die Order
	Übergibt diese an die Prozedur spDefineOrderStatusAndProcessIfCommissioned
	Diese erledigt folgendes:
		1. Check, ob Bestellung lieferbar aus einem der Lager.
			1.1 falls ja:
				- Bestand aus dem entsprechenden Lager wird reduziert
				- der Bestellstatus wird auf "beauftragt" gesetzt
				- Rechnung wird erzeugt mit status = "unpaid"
			1.2 falls nein:
				- keine Bestandsreduktion
				- Bestellstatus wird auf "abgelehnt" gesetzt
				- keine Rechnung wird angelegt
		2. In beiden Fällen wird an diesen Trigger hier der resultierende Status der Bestellung zurückgegeben.
	Am Ende kommt als Resultat also entweder order+invoice mit BEstandsreduzierung bei inventory raus, ODER nur order
*/
		

AS 
BEGIN


---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;


----------------------------------------------------------Variablendeklaration und zwischenspeichern der INSERT-Werte
	----Variablendeklaration für Eingangswerte des INSERTS. Diese müssen übergeben werden an Folgeprozedur.
	DECLARE @insertedOrderID INT;
	DECLARE @insertedCustomerID INT;
	DECLARE @insertedProductID BIGINT; 
	DECLARE @insertedOrderQuantity INT;
	DECLARE @insertedStatusID INT;
	DECLARE @insertedCreated_at DATETIME;
	
	--- temporäre Eingangswerte aus INSERT holen
	SELECT	@insertedOrderID = i.id,
			@insertedCustomerID = i.customer_id,
			@insertedProductID = i.product_id,
			@insertedOrderQuantity = i.quantity,
			@insertedStatusID = i.status_id,
			@insertedCreated_at = i.created_at			-- hier wird das Erzeugungsdatum der Rechnung übergeben! Dies muss NICHT das Tagesdatum sein!! (kann aber...)
	FROM inserted i
	
	PRINT (CHAR(13) + CHAR(10) + 'Innerhalb Trigger trgWhenInsertingOrderDoStuff in Prozedur spDefineOrderStatusAndProcessIfCommissioned springen')

	---- Übergabe an zentrale Prozesskette; 
	EXEC spDefineOrderStatusAndProcessIfCommissioned 
		@orderID = @insertedOrderID, 
		@customerID = @insertedCustomerID, 
		@ProductID = @insertedProductID, 
		@OrderQuantity = @insertedOrderQuantity, 
		@statusID = @insertedStatusID, 
		@created_at = @insertedCreated_at		-- hier wird "echtes" Datum aus anzulegender order REINGEGEBEN!
	
	PRINT (CHAR(13) + CHAR(10) + 'Innerhalb Trigger trgWhenInsertingOrderDoStuff aus Prozedur spDefineOrderStatusAndProcessIfCommissioned zurückgekommen')

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


END;

GO

ALTER TABLE [dbo].[orders] ENABLE TRIGGER [trgWhenInsertingOrderDoStuff]
GO


