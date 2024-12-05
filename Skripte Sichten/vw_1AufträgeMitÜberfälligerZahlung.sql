USE [ProjektarbeitPP]
GO

/****** Object:  View [dbo].[vw_1Auftr�geMit�berf�lligerZahlung]    Script Date: 10.10.2024 19:47:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER       VIEW [dbo].[vw_1Auftr�geMit�berf�lligerZahlung]
WITH SCHEMABINDING

------------------------------Beschreibung ----------------
/*
	Diese Sicht zeigt alle Auftr�ge (order+invoice) mit �berf�lliger Zahlung.
	Beachte: 
	--	Es wird hier nach dem Zahltag eingeschr�nkt, lediglich bezahlte Rechnungen werden ausgeschlossen.
	--	Es k�nnen also auch Auftr�ge auftauchen, bei denen der Zahltag in der Vergangenheit liegt, und bei denen die Rechnung noch nicht auf "overdue" gesetzt worden ist!
	--	Die View hat also zwei Zwecke:
		-- Unterst�tzung bei der Identifikation von Auftr�gen, die bereits den entsprechenden "�berf�llig" Status haben (und z.B. auf abgeschlossen, also bezahlt gesetzt werden sollen)
		-- Unterst�tzung bei der Identifikation von Auftr�gen, deren Zahltag verstrichen sind, die aber noch nicht den "�berf�llig" Status haben.

*/
AS (

SELECT	TOP 1000	Bestell_ID,
					Bestellstatus,
					Auftragseingang,
					Kunden_ID,
					Produkt_ID,
					Bestellmenge,
					Umsatz,
					Mahngeb�hr,
					Zahltag,
					Rechnungsstatus,
					Rechnungs_ID,
					Status_Auftrag
FROM dbo.vw_0Auftr�ge
WHERE Zahltag < CAST(getdate() AS nvarchar(80)) AND (Status_Auftrag LIKE '%�berf�llig%' OR STATUS_Auftrag LIKE '%offen%' )
ORDER BY Status_Auftrag DESC

	)
GO


