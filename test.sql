--test script
DECLARE @RESULTS table(
	name varchar(20),
	test_value varchar(50),
	right_value varchar(50)
);

DECLARE @waiter_code VARCHAR(4)
DECLARE @waiter_name VARCHAR(50)
DECLARE @bill_number INT

--достаём любого официанта
SELECT @waiter_code = MAX(code) FROM HR
SELECT @waiter_name = name FROM HR WHERE code = @waiter_code

--создать счёт в красном зале на первом столике, с количеством людей 3
exec @bill_number = CREATE_BILL "Красный 1", @waiter_code, 3

--SELECT * FROM BILL
--SELECT * FROM MENU_ITEM
--DELETE FROM BILL_ITEM

-- удаляем расписание на сегодня
DELETE FROM PRICE_SCHEDULE WHERE menu_item IN (SELECT id FROM MENU_ITEM WHERE code = '7777' OR code = '7778' OR code = '7779' OR code = '7780')
--создание тестового блюда поштучного
DELETE FROM MENU_ITEM WHERE name = 'TEST item fi'
INSERT INTO MENU_ITEM(name, short_name, section, [type], portion, startPortion, code, pricePortion, price, workshop, available, [order])
	VALUES(
		'TEST item fi',
		'TEST item fi',
		(SELECT max(id) FROM MENU_SECTION),
		'fi',
		1,
		1,
		'7777',
		1,
		100,
		(SELECT id FROM workshop WHERE name = 'Горячий'),
		2,
		100
	)
--создание тестового блюда весового
DELETE FROM MENU_ITEM WHERE name = 'TEST item fp'
INSERT INTO MENU_ITEM(name, short_name, section, [type], portion, startPortion, code, pricePortion, price, workshop, available, [order])
	VALUES(
		'TEST item fp',
		'TEST item fp',
		(SELECT max(id) FROM MENU_SECTION),
		'fi',
		100,
		300,
		'7778',
		100,
		80,
		(SELECT id FROM workshop WHERE name = 'Горячий'),
		2,
		100
	)

--создание тестового напитка по граммам
DELETE FROM MENU_ITEM WHERE name = 'TEST item dp'
INSERT INTO MENU_ITEM(name, short_name, section, [type], portion, startPortion, code, pricePortion, price, workshop, available, [order])
	VALUES(
		'TEST item dp',
		'TEST item dp',
		(SELECT max(id) FROM MENU_SECTION),
		'fi',
		50,
		100,
		'7779',
		100,
		56,
		(SELECT id FROM workshop WHERE name = 'Бар'),
		2,
		100
	)
--создание тестового напитка поштучного
DELETE FROM MENU_ITEM WHERE name = 'TEST item di'
INSERT INTO MENU_ITEM(name, short_name, section, [type], portion, startPortion, code, pricePortion, price, workshop, available, [order])
	VALUES(
		'TEST item di',
		'TEST item di',
		(SELECT max(id) FROM MENU_SECTION),
		'fi',
		1,
		1,
		'7780',
		1,
		35,
		(SELECT id FROM workshop WHERE name = 'Бар'),
		2,
		100
	)

--создание тестового напитка поштучного
DELETE FROM INGREDIENT WHERE name = 'TEST item'
INSERT INTO INGREDIENT(name, section, code, price, available)
	VALUES(
		'TEST item',
		(SELECT max(id) FROM INGR_SECTION),
		'9999',
		4,
		2
	)

DECLARE @workshop_di varchar(20)
DECLARE @workshop_dp varchar(20)
DECLARE @workshop_fi varchar(20)
DECLARE @workshop_fp varchar(20)
DECLARE @price varchar(50)



-- добавление позиций в заказ
--Описание CREATE_BILL_ITEM @bill_number, @waiter_code, @menu_item_code, @portion , @count, @later, @away, @workshop output
exec CREATE_BILL_ITEM @bill_number, @waiter_code,'7777', 1 , 1,  0, 0, @workshop_fi output
SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7777')
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '100') 
exec CREATE_BILL_ITEM @bill_number, @waiter_code,'7777', 1 , 2,  0, 0, @workshop_fi output
SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7777') and [count] = 2
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '100') 
exec CREATE_BILL_ITEM @bill_number, @waiter_code,'7778', 800 , 1,  0, 0, @workshop_fp output
SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7778')
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '640') 
exec CREATE_BILL_ITEM @bill_number, @waiter_code,'7779', 200 , 1,  0, 0, @workshop_dp output
SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7779')
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '112') 
exec CREATE_BILL_ITEM @bill_number, @waiter_code,'7780', 1 , 7,  0, 0, @workshop_di output
SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7780')
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '35') 

INSERT INTO @RESULTS VALUES('Цех заказа', @workshop_fi, 'Горячий');
INSERT INTO @RESULTS VALUES('Цех заказа', @workshop_fp, 'Горячий');
INSERT INTO @RESULTS VALUES('Цех заказа', @workshop_dp, 'Бар');
INSERT INTO @RESULTS VALUES('Цех заказа', @workshop_di, 'Бар');

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '1297');

--добавление ингредиентов в блюдо
DECLARE @bill_item INT
DECLARE @menu_item INT
SELECT @menu_item = id FROM MENU_ITEM WHERE code = '7777'
-- выбираем позицию и любой ингредиент с ценой
SELECT @bill_item = id FROM BILL_ITEM WHERE bill = @bill_number AND menu_item = @menu_item AND [count] = 1
-- заносим игредиент в таблицу
exec CREATE_BILL_ITEM_RECIPE @bill_item,'9999', 1

SELECT TOP 1 @price = CAST(price as varchar(50)) 
	FROM BILL_ITEM 
	WHERE bill = @bill_number AND menu_item IN (SELECT id from MENU_ITEM where code = '7777') and [count] = 1
INSERT INTO @RESULTS VALUES('Цена блюда с инг', @price , '104') 

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '1301');

/*SELECT b.bill, b.count, b.portion, m.name, m.code, m.price 'menu_item price' , b.price
	FROM BILL_ITEM b 
		INNER JOIN MENU_ITEM m ON m.id = b.menu_item
	WHERE bill = 1 */

--SELECT * FROM BILL_ITEM

-- удаляем все расписания для наших блюд

--обновляем расписание на сегодня - фиксированная цена
SELECT @menu_item = id FROM MENU_ITEM WHERE code = '7780'
SELECT @bill_item = id FROM BILL_ITEM WHERE bill = @bill_number AND menu_item = @menu_item

INSERT INTO PRICE_SCHEDULE(menu_item, dttm, fixed_price,sale) VALUES(@menu_item,GETDATE(), 30, NULL)

exec UPDATE_BILL_ITEM_PRICE @bill_item
exec UPDATE_BILL_PRICE @bill_number


SELECT TOP 1 @price = CAST(price as varchar(50)) FROM BILL_ITEM WHERE id = @bill_item
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '30') 

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '1266');


--обновляем расписание на сегодня - скидка
SELECT @menu_item = id FROM MENU_ITEM WHERE code = '7779'
SELECT @bill_item = id FROM BILL_ITEM WHERE bill = @bill_number AND menu_item = @menu_item

INSERT INTO PRICE_SCHEDULE(menu_item, dttm, fixed_price,sale) VALUES(@menu_item,GETDATE(), NULL, 10)

exec UPDATE_BILL_ITEM_PRICE @bill_item
exec UPDATE_BILL_PRICE @bill_number


SELECT TOP 1 @price = CAST(price as varchar(50)) FROM BILL_ITEM WHERE id = @bill_item
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '100,8') 

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '1254,8');

/*SELECT m.name, s.sale, s.fixed_price
	FROM PRICE_SCHEDULE s INNER JOIN MENU_ITEM m ON m.id = s.menu_item
	WHERE CAST(s.dttm as DATE) = CAST ( GETDATE() AS DATE)*/


-- введение аванса

UPDATE BILL set imprest = 700 WHERE number = @bill_number

exec UPDATE_BILL_PRICE @bill_number

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '554,8');

-- введение скидки на счёт

UPDATE BILL set sale = 5 WHERE number = @bill_number

exec UPDATE_BILL_PRICE @bill_number

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '507,6');

--обновляем расписание на сегодня - скидка на блюдо - не должно включаться в общую скидку
SELECT @menu_item = id FROM MENU_ITEM WHERE code = '7778'
SELECT @bill_item = id FROM BILL_ITEM WHERE bill = @bill_number AND menu_item = @menu_item

INSERT INTO PRICE_SCHEDULE(menu_item, dttm, fixed_price,sale) VALUES(@menu_item,GETDATE(), NULL, 10)

exec UPDATE_BILL_ITEM_PRICE @bill_item
exec UPDATE_BILL_PRICE @bill_number


SELECT TOP 1 @price = CAST(price as varchar(50)) FROM BILL_ITEM WHERE id = @bill_item
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '576') 

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '475,6');

exec UPDATE_BILL_ITEM @bill_item, 4, 200, 0, 0  

SELECT TOP 1 @price = CAST(price as varchar(50)) FROM BILL_ITEM WHERE id = @bill_item
INSERT INTO @RESULTS VALUES('Цена блюда (шт)', @price , '576') 

SELECT @price = CAST(total as varchar(50)) FROM BILL WHERE number = @bill_number
INSERT INTO @RESULTS VALUES('Сумма счёта', @price, '475,6');

SELECT * FROM @RESULTS

