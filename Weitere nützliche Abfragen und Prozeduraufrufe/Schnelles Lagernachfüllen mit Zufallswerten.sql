Use PracticeDatabase
GO


--------------------Schnelles Lagernachf�llen mit Zufallswerten
		
		-- Beachte: es gibt 60 inventory-IDs (f�r jedes der 30 Produkte 2 Lager)!
		-- Hilfsvariablen:
		DECLARE @Counter1 INT = 0;
		DECLARE @renewStock INT;
		-- Schleife zum Bef�llen aller Best�nde:
		WHILE @Counter1 < 60 + 1 -- alle 60 inventory-IDs durchgehen und mit
		BEGIN
				--SET @renewStock = 8    
				SET @renewstock = FLOOR(10 + (RAND() * (30 - 10 + 1)))		---- F�llt Best�nde mit Zufallswerten zwischen 10 und 30
				UPDATE	inventory
				SET		stock = @renewStock
				WHERE id = @Counter1

				SET @Counter1 = @Counter1 + 1;
		END;

		-- Stolz aufgef�llte Best�nde betrachten
		select * from inventory
