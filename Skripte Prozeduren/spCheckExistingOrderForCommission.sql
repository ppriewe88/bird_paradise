USE [ProjektarbeitPP]
GO

/****** Object:  StoredProcedure [dbo].[spCheckExistingOrderForCommission]    Script Date: 10.10.2024 15:41:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE OR ALTER  PROCEDURE [dbo].[spCheckExistingOrderForCommission]

----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Soll für eine existierende Bestellung im Status 3 = "abgelehnt" prüfen, ob sie beauftragt werden kann (über Prozedur spDefineOrderStatusAndProcessIfCommissioned der zentralen Prozesskette). Wenn schon eine Rechnung am Auftrag hängt, wird NICHTS getan (das entspricht Fällen, in denen der status der order 1=beauftragt oder 2=geliefert ist!)!
*/
--------------- Übergebene Variablen aus zu prüfender Bestellung (nur order-ID erforderlich)
			@orderID_checkforcomm INT,			
			-- optionaler Parameter für Zeitstempel
			@created_at_optional DATETIME = NULL			 


AS
BEGIN

-- PRINT @created_at_optional

---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;


	PRINT 'Beginne Prozedur spCheckExistingOrderForCommission'
----Variablendeklaration für Eingangswerte des INSERTS. Diese müssen übergeben werden an Folgeprozedur.
	DECLARE @CustomerID_checkforcomm INT;
	DECLARE @ProductID_checkforcomm BIGINT; 
	DECLARE @OrderQuantity_checkforcomm INT;
	DECLARE @StatusID_checkforcomm INT;
	--DECLARE @Created_at_checkforcomm DATETIME;


----- Prüfvariable, zur Prüfung ob nicht doch eine Rechnung am Auftrag hängt.
	DECLARE @checkOrderInvoices nvarchar(20);

---- temporäre Eingangswerte aus INSERT holen
	SELECT	@OrderID_checkforcomm = o.id,
			@CustomerID_checkforcomm = o.customer_id,
			@ProductID_checkforcomm = o.product_id,
			@OrderQuantity_checkforcomm = o.quantity,
			@StatusID_checkforcomm = o.status_id	
	FROM orders o
	WHERE o.id = @orderID_checkforcomm
	
	----  Sicherheitscheck: Hat der Auftrag nicht vielleicht doch schon eine Rechnung (es kann nur eine geben!)? Dann wird nichts getan! 
	SELECT	@checkOrderInvoices =
			CASE 
				WHEN i.id IS NOT NULL THEN CAST(i.id AS nvarchar(20))
				ELSE 'No invoice'
			END	
	FROM dbo.orders o
	LEFT JOIN dbo.invoices i ON o.id = i.order_id
	WHERE o.id = @OrderID_checkforcomm;			
	
	---- zu übergebenden Zeitstempel festlegen:

	-- Achtrung: der Zeitstempel wird hier auf getdate gesetzt, wenn nichts reinkam!! Wenn etwas reinkam, wird der eingegangene Wert verwendet!
	SET @created_at_optional = ISNULL(@created_at_optional, GETDATE());


	--------- loslegen

	IF @checkOrderInvoices = 'No invoice'
		BEGIN
			---- Übergabe an zentrale Prozesskette; 
			EXEC spDefineOrderStatusAndProcessIfCommissioned 
				@orderID = @orderID_checkforcomm, 
				@customerID = @CustomerID_checkforcomm, 
				@ProductID = @ProductID_checkforcomm, 
				@OrderQuantity = @OrderQuantity_checkforcomm, 
				@statusID = @StatusID_checkforcomm, 
				@created_at = @created_at_optional		-- hier wird das TAGESDATUM übergeben wenn von außen nix reinkommt; wenn von außen was reinkommt, wird der eingegangene Input übergeben!!
	
		END
	ELSE PRINT 'Für die Bestellung gibt es schon eine Rechnung mit der Rechnungs-ID ' + CAST(@checkOrderInvoices AS nvarchar(10)) + '. Es wurd nicht nochmal eine Rechnung angelegt.'

	PRINT 'Beende Prozedur spCheckExistingOrderForCommission'

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


