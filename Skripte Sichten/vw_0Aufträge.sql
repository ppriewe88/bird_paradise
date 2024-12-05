USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_0Auftr�ge]    Script Date: 10.10.2024 19:41:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE OR ALTER         VIEW [dbo].[vw_0Auftr�ge] 
WITH SCHEMABINDING

------------------------------Beschreibung ----------------
/*
	Diese Sicht fasst Bestellungen und Rechnungen zu einer Sicht zusammen, da diese beiden Objekte gedanklich als "Auftrag" behandelt werden.
	Au�erdem einige viele Prozeduren stets auf beide Objekte Auswirkungen.
	In der Sicht wird entsprechend ein Auftragsstatus "Status_Auftrag" als "k�nstlicher" Status angezeigt.
	F�r den Auftragsstatus werden etliche F�lle unterschieden. 
	F�lle, die mit "Pr�fen" angezeigt werden, d�rften bei normaler Nutzung nicht vorkommen und sind als Sicherheitsnetz eingebaut.

*/
AS (
SELECT 
    o.id AS Bestell_ID, 
	'id = ' + CAST(os.id AS nvarchar(20)) +  ' , ' + os.name AS Bestellstatus,
	FORMAT(o.created_at, 'yyyy-MM-dd') AS Auftragseingang,
	--o.created_at AS Auftragseingang,
	o.customer_id AS Kunden_ID,
	o.product_id AS Produkt_ID,
	o.quantity AS Bestellmenge,
	i.id AS Rechnungs_ID,
	i.total_price AS Umsatz,
	i.total_price_discounted AS rabattierter_Umsatz,
	i.overdue_fee AS Mahngeb�hr,
	i.due_limit AS Zahlungsfrist,
	FORMAT(i.due_date, 'yyyy-MM-dd') AS Zahltag,
	--i.due_date AS Zahltag,
	'id = ' + CAST(invs.id AS nvarchar(20)) +  ' , ' + invs.name AS Rechnungsstatus,
	CASE
		-- Fall, Bestellung beauftragt, Rechnung unpaid:
		WHEN o.status_id = 1 AND i.status_id = 1			THEN 'Beauftragt, Zahlung offen'
		-- Fall, Bestellung beauftragt, Rechnung paid:
		WHEN o.status_id = 1 AND i.status_id = 2			THEN 'Inkonsistenter Zustand!'							-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
		-- Fall, Bestellung beauftragt, Rechnung overdue:
		WHEN o.status_id = 1 AND i.status_id = 3			THEN 'Zahlung �berf�llig!'	
		-- Fall Bestellung geliefert, Rechnung unpaid:
		WHEN o.status_id = 2 AND i.status_id = 1			THEN 'Pr�fen!! Geliefert, nicht gezahlt!'				-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
		-- Fall Bestellung geliefert, Rechnung paid:
		WHEN o.status_id = 2 AND i.status_id = 2			THEN 'Bezahlt & geliefert!!'
		-- Fall Bestellung geliefert, Rechnung overdue:
		WHEN o.status_id = 2 AND i.status_id = 3			THEN 'Pr�fen!! Geliefert, nicht gezahlt!'				-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
		-- Fall, Bestellung geliefert, keine Rechnung:
		WHEN o.status_id = 2 AND i.status_id IS NULL		THEN'Pr�fen!! Geliefert, Rechnung fehlt!'				-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
		-- Fall Bestellung abgelehnt, keine Rechnung
		WHEN o.status_id = 3 AND i.status_id IS NULL		THEN 'Abgelehnt!'
		-- Fall, dass Bestellung abgelehnt, aber trotzdem Rechnung vorhanden:
		WHEN o.status_id = 3 AND i.status_id IS NOT NULL	THEN 'Pr�fen!! Abgelehnt, aber Rechnung gestellt!'		-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
		-- Fall, dass keine Bestellung vorhanden, aber Rechnung vorhanden:
		When o.status_ID = NULL AND i.status_id IS NOT NULL THEN 'Pr�fen!! Bestellung fehlt, Rechnung da!'			-- tritt bei normaler Verwendung nicht auf. Zur Sicherheit eingebaut
	END AS Status_Auftrag
FROM 
    dbo.orders o
LEFT JOIN 
    dbo.invoices i ON i.order_id = o.id
LEFT JOIN 
    dbo.orders_status os ON o.status_id = os.id
LEFT JOIN 
    dbo.invoices_status invs ON i.status_id = invs.id
	)
GO


