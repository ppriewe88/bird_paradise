Use PracticeDatabase
GO


--------------------Schnelles Lagernachfüllen mit Zufallswerten
		
		-- Beachte: es gibt 60 inventory-IDs (für jedes der 30 Produkte 2 Lager)!
		-- Hilfsvariablen:
		DECLARE @Counter1 INT = 0;
		DECLARE @renewStock INT;
		-- Schleife zum Befüllen aller Bestände:
		WHILE @Counter1 < 60 + 1 -- alle 60 inventory-IDs durchgehen und mit
		BEGIN
				--SET @renewStock = 8    
				SET @renewstock = FLOOR(10 + (RAND() * (30 - 10 + 1)))		---- Füllt Bestände mit Zufallswerten zwischen 10 und 30
				UPDATE	inventory
				SET		stock = @renewStock
				WHERE id = @Counter1

				SET @Counter1 = @Counter1 + 1;
		END;

		-- Stolz aufgefüllte Bestände betrachten
		select * from inventory
