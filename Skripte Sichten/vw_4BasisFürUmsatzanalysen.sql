USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_4BasisFürUmsatzanalysen]    Script Date: 10.10.2024 20:17:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
Diese Sicht dient als Vorlage für weitere Umsatzanalysen
*/


CREATE OR ALTER     VIEW [dbo].[vw_4BasisFürUmsatzanalysen]
WITH SCHEMABINDING

AS
(

SELECT	i.id AS Rechnungs_ID,
		i.total_price AS Umsatz,
		p.category_id AS Warengruppe,
		o.customer_id AS Kunden_ID,
		o.quantity AS Bestellmenge,
		p.id AS Produkt_ID,
		p.purchase_price AS Einkaufspreis,
		p.sale_price AS Verkaufspreis,
		p.sale_price / 1.19 AS Verkaufspreis_ohne_MWSt,
		p.sale_price / 1.19 * o.quantity - p.purchase_price * o.quantity AS Rohgewinn,
		p.supplier_id AS Lieferanten_ID
FROM dbo.invoices i
JOIN dbo.orders o ON i.order_id = o.id
JOIN dbo.products p ON o.product_id = p.id
WHERE i.status_id = 2


) 
GO


