USE [ProjektarbeitPP]
GO

/****** Object:  Trigger [dbo].[trgDeleteInvoicesOnlyWhenNoOrder]    Script Date: 10.10.2024 17:03:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE OR ALTER     TRIGGER [dbo].[trgDeleteInvoicesOnlyWhenNoOrder]
ON [dbo].[invoices]


AFTER DELETE ---------------legt die Eigenschaft fest, dass nach Insert ausgeführt wird!!


----XXXXXXXXXXXXXXXXXXX  Beschreibung   XXXXXXXXXXXXXXXX
/*
	Verhindert löschen von Rechnungen wenn es noch eine Order zur Rechnung gibt
*/
		

AS
BEGIN

	BEGIN TRY
    -- Beginne Transaktion
    BEGIN TRANSACTION;


        -- Variable um order_id aus Rechnung zu holen
        DECLARE @order_id_of_invoice INT;

        -- order_id aus der Tabelle "deleted" holen (die gelöschte Rechnung)
        SELECT @order_id_of_invoice = d.order_id
        FROM deleted d;

        -- Ausgabe der order_id (optional für Debugging)
        PRINT @order_id_of_invoice;

        -- Prüfen, ob die order_id NULL ist
        IF @order_id_of_invoice IS NULL
        BEGIN
            RAISERROR('Löschen nicht möglich! Entweder: Order_id in Rechnung ist NULL (unwahrscheinlich). Oder: Rechnung existiert nicht mehr (wahrscheinlich)! Da stimmt was nicht, bitte Rechnung und evt. Bestellung prüfen!', 16, 1);
            ROLLBACK TRANSACTION; -- Transaktion abbrechen
            RETURN; -- Beenden, da der Fehler behandelt wurde
        END;

        -- Prüfen, ob die Bestellung noch existiert
        IF EXISTS (SELECT 1 FROM orders o WHERE o.id = @order_id_of_invoice)
        BEGIN
            RAISERROR('Rechnung kann nicht gelöscht werden!! Es gibt noch eine Bestellung zu dieser Rechnung!', 16, 1);
            ROLLBACK TRANSACTION; -- Transaktion abbrechen
            RETURN; -- Beenden, da der Fehler behandelt wurde
        END;

    -- Wenn alles erfolgreich war, die Transaktion committen
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

ALTER TABLE [dbo].[invoices] ENABLE TRIGGER [trgDeleteInvoicesOnlyWhenNoOrder]
GO


