USE [ProjektarbeitPP]
GO

/****** Object:  StoredProcedure [dbo].[spCreateInvoiceOnOrder]    Script Date: 10.10.2024 14:19:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER  PROCEDURE [dbo].[spCreateInvoiceOnOrder]

----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Diese Prozedur soll eine Rechnung für eine existierende Bestellung anlegen. 
	Sie wird innerhalb der Prozedur spDefineOrderStatusAndProcessIfCommissioned aufgerufen. 
	Diese checkt vorher die Bestände im Rahmen der Lieferung und passt diese ggf. an. Bei erfolgreicher Bestellung wird (unter anderem) diese Prozedur hier gestartet. Sie legt zur durchgeführten Bestellung die zugehörige Rechnung an und holt dabei auch vom Kunden die Info, ob eventuell rabattiert wird.


	Dazu wird hier folgende Logik ausgeführt:
		- Bestelldaten holen (Menge, Preis)
		- Rabatt Prozentsatz aus Kundendatensatz holen (default 0)
		- rabattierter Gesamtpreis ausrechnen
		- Rechnung anlegen, entsprechenden Statuseintrag setzen (harter Status 1 = unpaid)


*/

--------------- Übergebene Variablen
			--- order-ID, wird zwingend von der Prozedur als Eingabe erwartet
			@order_id_for_invoice INT,	
			--- status-id, default 1 für "unpaid"; keine zwingende Eingabe erwartet. 
			@status_id INT = 1,					
			--- created_at; zur Übernahme von Datumswerten bei Aufruf aus der Prozedur spDefineOrderStatusAndProcessIfCommissioned. 
				-- Die Übergabekette ist hier: 
				--------- Aufruf durch trgWhenInsertingOrderDoStuff  ODER spCheckExistingOrderForCommission von "ganz außen", 
				----------------wenn von trgWhenInsertingOrderDoStuff kommend, wird Datum mitübergeben
				----------------wenn von spCheckExistingOrderForCommission kommend, wird Datum NICHT übergeben
				--------- dann spDefineOrderStatusAndProcessIfCommissioned. 
			@created_at_for_invoice DATETIME = NULL			 

AS
BEGIN

--------- Setze den Defaultwert für @created_at_default auf das aktuelle Datum, wenn NULL übergeben wird (also wenn KEIN Eingabedatum an die Prozedur übergeben wird, was beim automatischen Prozeduraufruf die Regel ist!

		SET @created_at_for_invoice = ISNULL(@created_at_for_invoice, GETDATE());

---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;


------------ Deklaration prozedurinterner Variablen
	DECLARE		@total_price DECIMAL(10,2),
				@customer_id INT,
				@customers_discount_percentage TINYINT,
				@total_discount DECIMAL(10,2),
				@total_price_discounted DECIMAL(10,2);
				
	PRINT (CHAR(13) + CHAR(10) + 'Beginne Prozedur spCreateInvoiceOnOrder')
	---------- Benötigte Produktdaten holen und zu (ggf. rabattiertem) Preis verrechnen 
		--Kunden-ID
		SELECT @customer_id = customer_id
		FROM orders
		WHERE id = @order_id_for_invoice
		-- Rabattwert (kann 0 oder durch Prozedur ChangeInvoiceStatusAndDoStuff anders belegt sein)
		SELECT	@customers_discount_percentage = discount			
		FROM	customers							
		WHERE	id = @customer_id
		--Gesamtpreis ausrechnen, Rabatt und rabattierten Gesamtpreis ausrechnen
		SELECT	@total_price = o.quantity * p.sale_price,						---- Gesamtpreis
				@total_discount = o.quantity * p.sale_price * @customers_discount_percentage / 100	---- abzuziehender Rabattwert
		FROM orders o
		JOIN products p
		ON o.product_id = p.id
		JOIN customers c
		ON o.customer_id = c.id
		WHERE o.id = @order_id_for_invoice

		SET @total_price_discounted = @total_price - @total_discount			----	Gesamtpreis minus abzuziehender Rabattwert
	
	----------Rechnung anlegen
	PRINT (CHAR(13) + CHAR(10) + 'Lege Rechnung an')

		------- Jetzt Rechnung anlegen
		INSERT INTO dbo.invoices
			   ([order_id]
			   ,[total_price]
			   ,[total_discount]
			   ,[total_price_discounted]
			   ,[status_id]
			   ,[created_at])
		VALUES	(
				@order_id_for_invoice,
				@total_price,
				@total_discount,
				@total_price_discounted,
				@status_id,
				@created_at_for_invoice);
				-- Hinweise: due_date wird hier nicht belegt; ist berechnetes Feld in Rechnung, wird automatisch auf 30 Tage in die Zukunft gesetzt!
		PRINT (CHAR(13) + CHAR(10) + 'HINWEIS: Rechnung angelegt')

		-------------- Erfolgreiche Ausführung, commit der Transaktion
		PRINT (CHAR(13) + CHAR(10) + 'Beende Prozedur spCreateInvoiceOnOrder')

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


