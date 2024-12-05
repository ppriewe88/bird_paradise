USE [ProjektarbeitPP]
GO

/****** Object:  StoredProcedure [dbo].[spCreateNewOrder]    Script Date: 10.10.2024 13:08:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE OR ALTER  PROCEDURE [dbo].[spCreateNewOrder]
		-- Optionaler Eingabewert für Menge. Rest wird zufällig generiert
		@quantity INT = 5

-----------------------------Beschreibung
/* 
Skript, um Auftrag erstellen, also Bestellung (order) und Rechnung (invoice) (mit Zeiten in Vergangenheit).
Das wird gemacht, indem eine Bestellung (order) per insert eingefügt wird. 
Das wiederum triggert an der order-Tabelle eine Prozedur, die prüft, ob genug BEstand vorhanden ist, und falls ja eine Rechnung anlegt.

Resultat dieser Prozedur hier ist im Erfolgsfall also:
	- entweder eine neue Bestellung im Status "beauftragt" mit zugehöriger Rechnung im Status "unpaid"
	- oder eine neue Bestellung im Status "abgelehnt" (weil nicht genügend Bestand da war) ohne Rechnung
*/

AS 
BEGIN

---- Try-Block
BEGIN TRY
-- Beginne Transaktion
BEGIN TRANSACTION;




------------------------------------------------------- Variablendeklarationen
	-- Variablen
	DECLARE @newOrderID INT;				-- variable, um währned des verlaufs hier neu entstandene order-ID auszulesen
	DECLARE @NewInvoiceID INT;				-- variable für neue rechnungs-id, die über order-Erzeugung ebenfalls generiert wird, und hier später an weitere Prozedur übergeben wird
	DECLARE @randomCreateDate DATETIME;		-- variable für zufallsdatum erzeugen
	

------------------------------------------------------- Beginn eigentliche Prozedur

		-------	Zufallsdatum zwischen 01.01.2024 und heute (getdate()) erzeugen. Gilt als Anlagedatum der BEstellung (und damit der Rechnung).

			SET @randomCreateDate =  FORMAT(DATEADD(DAY, FLOOR(RAND(CHECKSUM(NEWID())) * DATEDIFF(DAY, '2024-01-01', GETDATE())), '2024-01-01'), 'yyyy-dd-MM')
	
			PRINT @randomCreateDate		-- Kontrollausgabe

		------- Bestellung anlegen. Das triggert dann den Trigger trgWhenInsertingOrderDoStuff, der die zentrale Prozesskette startet

			INSERT INTO orders (customer_id, product_id, quantity, created_at, status_id)
				VALUES (
					FLOOR(RAND() * 20) + 1,  -- Zufällige Kunden-ID zwischen 1 und 20 (es gibt 20 Kunden in der Datenbank)
					FLOOR(RAND() * 30) + 1, -- Zufällige Produkt-ID (es gibt 30 Produkte in der Datenbank)
					@quantity,				-- Bestellmenge aus Prozedureingabe, bzw. default = 5
					@randomCreateDate,		-- Zufälliges Datum zwischen 01.01.2024 und heute
					1					    -- Zufällige Status-ID zwischen 1 und 3 (angenommen es gibt 3 Statuswerte)
				);

			-- hole die gerade entstandene order-ID zu Kontrollzwecken:
			SET @newOrderID = SCOPE_IDENTITY()
			
			---hole noch die Invoice-ID mithilfe der gerade entstandenen order-id (benutze für letztere SCOPE_IDENTITY)
			SELECT @NewInvoiceID = id
			FROM invoices 
			WHERE order_id = @newOrderID

			------ Resultat nach obigen Schritten ist nun erstmal eine Bestellung (order) und (falls genug Bestand vorhanden war) eine Rechnung (invoice) im Status unpaid
			PRINT (CHAR(13) + CHAR(10) + 'Es wurde eine Bestellung erzeugt. order-ID:     ' + CAST(@newOrderID AS nvarchar(80)))
			PRINT (CHAR(13) + CHAR(10) + 'Falls hier rechts eine Zahl steht, wurde auch eine Rechnung erzeugt (bei NULL nicht). invoice-ID:     ' + CAST(@newInvoiceID AS nvarchar(80)))


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


