-- создание счетов
DROP PROCEDURE CREATE_BILL
GO
CREATE PROCEDURE CREATE_BILL(
@room_table VARCHAR(20), @waiter_code VARCHAR(4), @people_count INT)
AS
BEGIN
	DECLARE @nextId INT
	
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		UPDATE [PROPERTIES] SET [value_int]=[value_int]+1 WHERE [name] = 'bill'
		SELECT @nextId=[value_int]-1 FROM [PROPERTIES] WHERE [name]='bill'

		INSERT INTO [BILL]([number],[room_table],[waiter],[open_time],[people_count], sale, imprest)
			VALUES(@nextId,
				   @room_table,
				   (SELECT [id] FROM [HR] WHERE [code] = @waiter_code),
				   CURRENT_TIMESTAMP,
				   @people_count,
				   0,
				   0
				  )
		IF NOT EXISTS (SELECT * FROM PLACE WHERE [name] = @room_table)
		BEGIN
			INSERT INTO PLACE(name,status) VALUES(@room_table,1)
		END
	COMMIT TRANSACTION
	return @nextId
END
GO
-- закрытие счетов
DROP PROCEDURE CLOSE_BILL
GO
CREATE PROCEDURE CLOSE_BILL
(@numberBill INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [BILL] 
		SET [close_time]=CURRENT_TIMESTAMP 
		WHERE [number]=@numberBill
	COMMIT TRANSACTION

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	IF NOT EXISTS(SELECT * FROM [BILL] 
			WHERE [close_time] IS NULL
			AND [room_table] = (SELECT [room_table] FROM [BILL] WHERE [number]=@numberBill)
		 )	
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
		BEGIN TRANSACTION
		UPDATE [PLACE]
			SET [status] = 0
			WHERE [name] = (SELECT [room_table] FROM [BILL] WHERE [number]=@numberBill)
		COMMIT TRANSACTION
	END
END
GO
-- создание позиции в счёте
-- возвращает цех, на который надо отправлять заказ
DROP PROCEDURE CREATE_BILL_ITEM
GO
CREATE PROCEDURE CREATE_BILL_ITEM
(@numberBill INT, @waiter_code VARCHAR(4), @menu_item_code VARCHAR(4), @portion INT, @count INT, @later BIT, @away BIT, @workshop VARCHAR(20) output, @id INT output)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		DECLARE @menu_item_id INT
		DECLARE @menu_item_workshop INT

		SELECT @menu_item_id = id, @menu_item_workshop = workshop FROM MENU_ITEM WHERE code = @menu_item_code

		INSERT INTO [BILL_ITEM](bill,waiter,menu_item, portion, count, price, order_time, later, away) VALUES(@numberBill,
						 (SELECT [id] FROM [HR] WHERE [code]=@waiter_code),
						 @menu_item_id,
						 @portion,
						 @count,
						 0,
						 CURRENT_TIMESTAMP,
						 @later,
						 @away);
		DECLARE @bill_item INT
		SELECT @bill_item = CAST(SCOPE_IDENTITY() AS INT)
		EXEC UPDATE_BILL_ITEM_PRICE @bill_item
		EXEC UPDATE_BILL_PRICE @numberBill
		SELECT @workshop = name FROM [WORKSHOP] where id = @menu_item_workshop
	COMMIT TRANSACTION
END
GO

-- создание позиции в счёте. Это специальные блюда, которые могут отправлять только админы
-- Их нет в меню, и админы сами задают цену
-- возвращает цех, на который надо отправлять заказ
DROP PROCEDURE CREATE_SPECIAL
GO
CREATE PROCEDURE CREATE_SPECIAL
(@numberBill INT, @name VARCHAR(80), @short_name VARCHAR(40), @price MONEY, @workshop VARCHAR(20), @count INT, @later BIT, @away BIT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	DECLARE @workshop_id INT
	SELECT @workshop_id = id FROM WORKSHOP WHERE name = @workshop
	INSERT INTO [SPECIAL](bill, name, short_name, price, count, order_time, later, away) VALUES(@numberBill,
					 @name,
					 @short_name,
					 @price,
					 @count,
					 CURRENT_TIMESTAMP,
					 @later,
					 @away);
	EXEC UPDATE_BILL_PRICE @numberBill
	COMMIT TRANSACTION
END
GO

-- Эта процудура должна изменять ингредиенты в неотправленных блюдах
-- Для этого в предыдущей версии мы удаляли ВСЕ записи для данного bill_item и заново их записывали - так проще и понятнее
DROP PROCEDURE CREATE_BILL_ITEM_RECIPE
GO
CREATE PROCEDURE CREATE_BILL_ITEM_RECIPE
(@bill_item INT, @code VARCHAR(4), @isToAdd BIT)
AS                                	
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [BILL_ITEM_RECIPE](bill_item, ingredient, [add]) VALUES(@bill_item,
						     (SELECT [id] FROM [INGREDIENT] WHERE [code] = @code), 
						     @isToAdd
						    )
	EXEC UPDATE_BILL_ITEM_PRICE @bill_item
	DECLARE @bill_number INT
	SELECT @bill_number = bill FROM BILL_ITEM WHERE id = @bill_item
	EXEC UPDATE_BILL_PRICE @bill_number
	COMMIT TRANSACTION
END
GO
-- обновить значение цены для позиции
DROP PROCEDURE UPDATE_BILL_ITEM_PRICE
GO
CREATE PROCEDURE UPDATE_BILL_ITEM_PRICE
(@bill_item INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	DECLARE @price MONEY
	DECLARE @fixed_price MONEY
	DECLARE @sale INT
	SELECT @fixed_price = fixed_price, @sale = sale 
		FROM PRICE_SCHEDULE s INNER JOIN MENU_ITEM m ON s.menu_item = m.id
								INNER JOIN BILL_ITEM b ON  b.menu_item = m.id
		WHERE b.id = @bill_item AND CAST(s.dttm as DATE) = CAST ( b.order_time AS DATE)
	IF ( @fixed_price IS NOT NULL)
	BEGIN
		SELECT  @price = @fixed_price * b.portion / [pricePortion] 
			FROM [MENU_ITEM] m INNER JOIN [BILL_ITEM] b ON b.menu_item = m.id 
			WHERE b.id = @bill_item
	END
	ELSE IF (@sale IS NOT NULL)
	BEGIN
		SELECT  @price = m.[price] * (100 - @sale) / 100 * b.portion / [pricePortion] 
			FROM [MENU_ITEM] m INNER JOIN [BILL_ITEM] b ON b.menu_item = m.id 
			WHERE b.id = @bill_item

	END
	ELSE
	BEGIN	
		SELECT  @price = m.[price] * b.portion / [pricePortion] 
			FROM [MENU_ITEM] m INNER JOIN [BILL_ITEM] b ON b.menu_item = m.id 
			WHERE b.id = @bill_item
	END
	SELECT @price = @price +  + COALESCE(SUM(i.price),0)
		FROM [INGREDIENT] i INNER JOIN [BILL_ITEM_RECIPE] r ON r.ingredient = i.id	
		WHERE r.[add] = 1 AND bill_item = @bill_item
	UPDATE [BILL_ITEM] SET price = @price WHERE id = @bill_item
	COMMIT TRANSACTION
END
GO
DROP PROCEDURE UPDATE_BILL_PRICE
GO
CREATE PROCEDURE UPDATE_BILL_PRICE
(@numberBill INT)
AS
BEGIN
	DECLARE @price MONEY
	DECLARE @imprest MONEY
	DECLARE @sale INT
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	-- выбор всех позиций без скидок на сегодня и не из Бара
	-- к ним применяется скидка
		SELECT @price = COALESCE(SUM(i.price * i.count),0)
			FROM BILL_ITEM i INNER JOIN BILL b ON b.[number] = i.bill 
							 INNER JOIN MENU_ITEM m ON m.id = i.menu_item
							 INNER JOIN WORKSHOP w ON w.id = m.workshop
							 LEFT JOIN PRICE_SCHEDULE s ON (s.menu_item = m.id AND CAST(s.dttm as DATE) = CAST ( i.order_time AS DATE))
			WHERE b.[number] = @numberBill AND w.name <> 'Бар' AND s.id IS NULL
		SELECT @sale = sale, @imprest = imprest FROM BILL WHERE [number] = @numberBill
		SET @price = @price * (100 - @sale) / 100
		-- выбор всех позиций из бара и уже со скидкой - к ним скидка не применяется
		SELECT @price = @price + COALESCE(SUM(i.price * i.count),0)
			FROM BILL_ITEM i INNER JOIN BILL b ON b.[number] = i.bill 
							 INNER JOIN MENU_ITEM m ON m.id = i.menu_item
							 INNER JOIN WORKSHOP w ON w.id = m.workshop
							 LEFT JOIN PRICE_SCHEDULE s ON (s.menu_item = m.id AND CAST(s.dttm as DATE) = CAST ( i.order_time AS DATE))
			WHERE b.[number] = @numberBill AND w.name = 'Бар' OR s.id IS NOT NULL
		-- выбор позиций специальных блюд
		-- к ним скидка не применяется	
		SELECT  @price = @price + COALESCE(SUM(price),0)
			FROM SPECIAL 
			WHERE bill = @numberBill
		-- убрать аванс	
		IF (@imprest < @price)
			SET @price = @price - @imprest
		ELSE
			SET @price = 0
		UPDATE BILL SET total = @price WHERE [number] = @numberBill
	COMMIT TRANSACTION
END
GO
DROP PROCEDURE UPDATE_BILL_ITEM
GO
CREATE PROCEDURE UPDATE_BILL_ITEM(@bill_item INT, @count INT, @portion INT, @later INT, @away INT)
AS
BEGIN
	UPDATE BILL_ITEM SET count = @count, portion = @portion, later = @later, away = @away
		WHERE id = @bill_item
	EXEC UPDATE_BILL_ITEM_PRICE @bill_item
	DECLARE @bill_number INT
	SELECT @bill_number = bill FROM BILL_ITEM WHERE id = @bill_item
	EXEC UPDATE_BILL_PRICE @bill_number
END