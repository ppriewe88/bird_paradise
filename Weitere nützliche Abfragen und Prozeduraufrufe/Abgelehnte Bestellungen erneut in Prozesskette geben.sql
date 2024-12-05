USE [ProjektarbeitPP]
GO
------------------------------------------------------------------------

------------------------------- Bestellungen nachträglich durchschieben
------ niedrigste ID aus abgelehnt-Bestellungen (status_id 3) ermitteln:
			DECLARE @lowestDeclinedID INT;
			SET @lowestDeclinedID = (		SELECT TOP 1 id 
										FROM orders
										WHERE status_id = 3 
										ORDER BY id ASC)
			PRINT @lowestDeclinedID
		---- Für diese ID die abgelehnt-Bestellung auf paid (@newstatus_id 2 als input) setzen, ODER auf overdue (@newstatus_id = 3 als input)!	
		EXEC spCheckExistingOrderForCommission @orderID_checkforcomm = @lowestDeclinedID

