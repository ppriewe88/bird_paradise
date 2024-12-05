USE [ProjektarbeitPP]
GO



------------------------------- Rabattkunden finden und "entgangene Umsätze" aufgrund der Rabatte anzeigen
			--Rabattkunden
			SELECT	COUNT(*)				 
			FROM customers c
			WHERE discount > 0
			-- Rabattfreie Kunden
			SELECT COUNT(*)
			FROM customers c
			WHERE discount = 0
			-- entgangene Umsätze
			SELECT	SUM(total_price) AS gemachter_Umsatz,
					SUM(total_discount) AS entgangener_Umsatz
			FROM customers c
			JOIN orders o ON o.customer_id = c.id
			JOIN invoices i ON i.order_id = o.id

	
