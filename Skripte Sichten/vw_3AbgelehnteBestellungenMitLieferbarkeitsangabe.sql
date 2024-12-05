USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_3AbgelehnteBestellungenMitLieferbarkeitsangabe]    Script Date: 10.10.2024 20:13:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE OR ALTER      VIEW [dbo].[vw_3AbgelehnteBestellungenMitLieferbarkeitsangabe]

WITH SCHEMABINDING

AS (

/*
Hier werden alle Bestellungen im Status 3 (abgelehnt) angezeigt. 
Diese Bestellungen wurden beim Anlegen abgelehnt, weil die viel Menge (quantity) angefragt wurde, um aus einem der Lager beliefert werden zu können.
Dies hilft, um gezielt abgelehnte Bestellungen erneut durch den Prozess zur Prüfung der Lieferbarkeit zu schieben (Prozedur spCheckExistingOrderForCommission).

Beachte: 
--		1. Es könnte sein, dass eine Bestellung (abgelehnt), die hier angezeigt wird, zwischenzeitlich lieferbar wäre, da das Lager aufgefüllt wurde.
--		2. Das ist gewünscht und richtig so. Daher zeigen wir zusätzlich beide Lager an, und ob aus dem jeweiligen Lager geliefert werden könnte.

*/

SELECT	o.id AS	Abgelehnte_Bestellung,
		(SELECT name FROM dbo.orders_status WHERE id = o.status_id) AS Bestellstatus,
		o.product_id  AS	Bestellte_Produkt_ID,
		o.quantity AS Bestellmenge,
		i.id AS Inventory_ID, 
		'Lager-ID = ' + CAST(i.storage_location_id AS nvarchar(80)) + '; ' + CAST((SELECT name FROM dbo.inventory_storagelocations WHERE id = i.storage_location_id) AS nvarchar(80)) AS Lagerort,
		i.stock AS Bestand, 
		i.min_stock AS Mindestbestand,
		CASE
			WHEN i.stock - o.quantity >= 0 THEN 'lieferbar'
			ELSE '..'
		END AS Lieferbarkeitsangabe
FROM dbo.orders o
JOIN dbo.inventory i ON i.product_id = o.product_id
WHERE o.status_id = 3


)
GO


