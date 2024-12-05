USE [ProjektarbeitPP]
GO



------------------------------- Rechnungen mit Zahltag < Tagesdatum auf "overdue" setzen.
		------ niedrigste ID aus Unpaid-Rechnungen (status_id 1) ermitteln:
			DECLARE @lowestOverdueID INT;
			SET @lowestOverdueID = (		SELECT TOP 1 id 
										FROM invoices
										WHERE status_id = 1 AND due_date < getdate()
										ORDER BY id ASC)
			PRINT @lowestOverdueID
		---- Für diese ID Unpaid-Rechnung auf overdue setzen!				
				EXEC spChangeInvoiceStatusAndDoStuff
					@invoiceID		= @lowestOverdueID,
					@newStatusID	= 3
		---- Stolz Ergebnisse anschauen
			select * from dbo.vw_0Aufträge WHERE Rechnungs_ID = @lowestUnpaidID
