USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_1AufträgeMitÜberfälligerZahlung]    Script Date: 10.10.2024 19:47:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER       VIEW [dbo].[vw_1AufträgeMitÜberfälligerZahlung]
WITH SCHEMABINDING

------------------------------Beschreibung ----------------
/*
	Diese Sicht zeigt alle Aufträge (order+invoice) mit überfälliger Zahlung.
	Beachte: 
	--	Es wird hier nach dem Zahltag eingeschränkt, lediglich bezahlte Rechnungen werden ausgeschlossen.
	--	Es können also auch Aufträge auftauchen, bei denen der Zahltag in der Vergangenheit liegt, und bei denen die Rechnung noch nicht auf "overdue" gesetzt worden ist!
	--	Die View hat also zwei Zwecke:
		-- Unterstützung bei der Identifikation von Aufträgen, die bereits den entsprechenden "überfällig" Status haben (und z.B. auf abgeschlossen, also bezahlt gesetzt werden sollen)
		-- Unterstützung bei der Identifikation von Aufträgen, deren Zahltag verstrichen sind, die aber noch nicht den "überfällig" Status haben.

*/
AS (

SELECT	TOP 1000	Bestell_ID,
					Bestellstatus,
					Auftragseingang,
					Kunden_ID,
					Produkt_ID,
					Bestellmenge,
					Umsatz,
					Mahngebühr,
					Zahltag,
					Rechnungsstatus,
					Rechnungs_ID,
					Status_Auftrag
FROM dbo.vw_0Aufträge
WHERE Zahltag < CAST(getdate() AS nvarchar(80)) AND (Status_Auftrag LIKE '%überfällig%' OR STATUS_Auftrag LIKE '%offen%' )
ORDER BY Status_Auftrag DESC

	)
GO


