USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_2KritischeLagerbest�nde]    Script Date: 10.10.2024 19:53:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE OR ALTER      VIEW [dbo].[vw_2KritischeLagerbest�nde]

WITH SCHEMABINDING

AS (

/*
Hier werden alle Lager ausgegeben, f�r die der aktuelle Bestand unter dem Mindestbestand ist

Beachte: 
--		1. Wir haben in dieser Sicht bewusst keine Infos �ber abgelehnte Bestellungen je Lager
--		2. F�r abgelehnte Bestellungen haben wir eine andere Sicht
--		3. Mit dieser Sicht hier k�nnen wir gezielt geleerte Lager auff�llen. 

*/
SELECT	i.id AS Inventory_ID, 
		i.product_id AS Produkt_ID,
		'Lager-ID = ' + CAST(i.storage_location_id AS nvarchar(80)) + '; ' + CAST((SELECT name FROM dbo.inventory_storagelocations WHERE id = i.storage_location_id) AS nvarchar(80)) AS Lagerort,
		i.stock AS Bestand, 
		i.min_stock AS Mindestbestand
FROM dbo.inventory i
WHERE i.stock < i.min_stock

)
GO


