SELECT TOP (1000) [Rechnungs_ID]
      ,[Gesamtumsatz]
      ,[Warengruppe]
      ,[Kunden_ID]
      ,[Lieferanten_ID]
  FROM [ProjektarbeitPP].[dbo].[vw_4BasisFürUmsatzanalysen]


  -------------------Kunde nach Rohgewinn ------------
  -- Wir geben uns nun eine Übersicht aus, die für jeden Kunden alle erzielten Umsätze (bez. Rechnungen) summiert, und den Rohgewinn ausgibt.
  -- Der Kunde mit dem meisten Rohgewinn steht ganz oben
	  SELECT	Kunden_ID, 
				COUNT(*) AS 'Anzahl bezahlte Rechnungen',
				SUM(Bestellmenge) AS 'Anzahl gekaufte Artikel',
				SUM(Umsatz) AS 'Gesammelter Umsatz',
				CAST(SUM(Rohgewinn) AS decimal(10,2)) AS 'erzielter Rohgewinn'			
	  FROM dbo.vw_4BasisFürUmsatzanalysen
	  GROUP BY Kunden_ID
	  ORDER BY CAST(SUM(Rohgewinn) AS decimal(10,2)) DESC

     -------------------Kunde nach Handelsspanne ------------
  -- Wir geben uns nun eine Übersicht aus, die für jeden Kunden alle erzielten Umsätze (bez. Rechnungen) summiert, zusätzlich die durchschnittl. Handelsspanne ausgibt.
  -- Der Kunde mit der größten Handelsspanne steht ganz oben
	  SELECT	Kunden_ID, 
				COUNT(*) AS 'Anzahl bezahlte Rechnungen',
				SUM(Bestellmenge) AS 'Anzahl gekaufte Artikel',
				SUM(Umsatz) AS 'Gesammelter Umsatz',
				CAST(SUM(Rohgewinn) AS decimal(10,2)) AS 'erzielter Rohgewinn',
				CAST(CAST(SUM(Rohgewinn) / SUM(Umsatz) * 100 AS decimal(10,2)) AS nvarchar(80)) + ' %' AS 'Durchschnittl. Handelsspanne'			
	  FROM dbo.vw_4BasisFürUmsatzanalysen
	  GROUP BY Kunden_ID
	  ORDER BY CAST(CAST(SUM(Rohgewinn) / SUM(Umsatz) * 100 AS decimal(10,2)) AS nvarchar(80)) + ' %' DESC
   
   
   -------------------Produkte und ihre Verkaufsdaten------------
   -- Hier nun eine Übersicht für Produkte, gewinnstärkste Produkte oben
		  SELECT	Produkt_ID,
					SUM(Bestellmenge) AS 'Verkaufte Stückzahl',
					SUM(Umsatz) AS 'Gesammelter Umsatz',
					CAST(SUM(Rohgewinn) AS decimal(10,2)) AS 'erzielter Rohgewinn'
		  FROM dbo.vw_4BasisFürUmsatzanalysen
		  GROUP BY Produkt_ID
		  ORDER BY CAST(SUM(Rohgewinn) AS decimal(10,2)) DESC


   ------------------- Warengruppen und ihre Verkaufsdaten------------
	-- Dasselbe nochmal für Warengruppen:
		 SELECT		Warengruppe,
					SUM(Bestellmenge) AS 'Anzahl verkaufte Produkte',
					SUM(Umsatz) AS 'Gesammelter Umsatz',
					CAST(SUM(Rohgewinn) AS decimal(10,2)) AS 'erzielter Rohgewinn'
		  FROM dbo.vw_4BasisFürUmsatzanalysen
		  GROUP BY Warengruppe
		  ORDER BY CAST(SUM(Rohgewinn) AS decimal(10,2)) DESC


