/*цеха для отправки на принтер*/
DROP TABLE [workshop]
GO
CREATE TABLE [workshop](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(20) NOT NULL
)
GO

/*Информационные таблицы*/
DROP TABLE [HR]
GO
CREATE TABLE [HR](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(100) NOT NULL UNIQUE,
	[code] varchar(4) NOT NULL,
	[isadmin] BIT DEFAULT 0 -- 0 - waiter, 1 - admin 
)
GO
DROP TABLE [MENU_SECTION]
GO
CREATE TABLE [MENU_SECTION](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(50) NOT NULL UNIQUE,
	[order] INT NOT NULL DEFAULT 100000,
	[show] INT NOT NULL CHECK([show] IN (0,1)) -- 0 - hide, 1 - show
)
GO
DROP TABLE [INGR_SECTION]
GO
CREATE TABLE [INGR_SECTION](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(50) NOT NULL UNIQUE,
	[show] INT NOT NULL CHECK([show] IN (0,1)) -- 0 - hide, 1 - show
)
GO
DROP TABLE [INGREDIENT]
GO
CREATE TABLE [INGREDIENT](
	[id] INT PRIMARY KEY IDENTITY,                 
	[name] VARCHAR(50) NOT NULL UNIQUE,
	[section] INT NOT NULL,
	[price] MONEY NOT NULL,
	[code] VARCHAR(4) NOT NULL,
	[available] INT NOT NULL CHECK([available] IN (0,1,2)) -- 0--hide, 1- not available, 2 - available
)
GO
DROP TABLE [MENU_ITEM]
GO
CREATE TABLE [MENU_ITEM](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(80) NOT NULL,
	[short_name] VARCHAR(40) NOT NULL,
	[section] INT NOT NULL,
	[type] VARCHAR(2) NOT NULL CHECK([type] IN ('dp','di','fp','fi')),
	[portion] INT,
	[startPortion] INT,
	[code] VARCHAR(4) NOT NULL,
	[pricePortion] INT,
	[price] MONEY NOT NULL,
	[workshop] INT NOT NULL,
	[available] INT NOT NULL CHECK([available] IN (0,1,2)), -- 0--hide, 1- not available, 2 - available
	[order] INT
)
GO
DROP TABLE [RECIPE]
GO
CREATE TABLE [RECIPE](
	[id] INT PRIMARY KEY IDENTITY,
	[menu_item] INT NOT NULL,
	[INGREDIENT] INT NOT NULL,
	[additional] INT DEFAULT 1
)
GO

DROP TABLE [PRICE_SCHEDULE]
GO
CREATE TABLE [PRICE_SCHEDULE](
	[id] INT PRIMARY KEY IDENTITY,
	[menu_item] INT NOT NULL,
	[dttm] DATETIME NOT NULL,
	[fixed_price] MONEY NOT NULL,
	[sale] DECIMAL,
	[sale_price] MONEY
)

/*Рабочие таблицы*/
DROP TABLE [BILL]
GO
CREATE TABLE [BILL](
	[id] INT PRIMARY KEY IDENTITY,
	[number] INT,
	[room_table] VARCHAR(20),
	[waiter] INT NOT NULL,
	[sent] BIT DEFAULT 0,
	[people_count] INT NOT NULL,
	[open_time] DATETIME NOT NULL,
	[close_time] DATETIME,
	[sale] INT,
	[imprest] MONEY,
	[total] MONEY DEFAULT 0.00
)
GO
CREATE UNIQUE INDEX [INDEX_BILL]
	ON [BILL]([number])
GO
DROP TABLE [BILL_ITEM]
GO
CREATE TABLE [BILL_ITEM](
	[id] INT PRIMARY KEY IDENTITY,
	[bill] INT NOT NULL,
	[waiter] INT NOT NULL,
	[menu_item] INT NOT NULL,
	[portion] DECIMAL DEFAULT 1,
	[count] INT NOT NULL,
	[price] MONEY NOT NULL,
	[order_time] DATETIME NOT NULL,
	[cancel_time] DATETIME,
	[later] BIT DEFAULT 0,
	[away] BIT DEFAULT 0
)
GO
DROP TABLE [SPECIAL]
GO
CREATE TABLE [SPECIAL](
	[id] INT PRIMARY KEY IDENTITY,
	[bill] INT NOT NULL,
	[name] VARCHAR(80) NOT NULL,
	[short_name] VARCHAR(40) NOT NULL,
	[price] MONEY NOT NULL,
	[count] INT NOT NULL,
	[order_time] TIME(0) NOT NULL,
	[cancel_time] TIME(0),
	[workshop] INT NOT NULL,
	[later] BIT DEFAULT 0,
	[away] BIT DEFAULT 0
)
GO

DROP TABLE [BILL_ITEM_RECIPE]
GO
CREATE TABLE [BILL_ITEM_RECIPE](
	[id] INT PRIMARY KEY IDENTITY,
	[bill_item] INT NOT NULL,
	[ingredient] INT NOT NULL,
	[add] BIT DEFAULT 1 -- 0 - delete, 1 -add
)
GO
DROP TABLE [FIELD_NAME]
GO
CREATE TABLE [FIELD_NAME](
	[id] INT PRIMARY KEY IDENTITY,
	[system_name] VARCHAR(50) NOT NULL,
	[russian_name] VARCHAR(50) NOT NULL
)
GO
DROP TABLE [OPTION]
GO
CREATE TABLE [OPTION](
	[id] INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(50) NOT NULL,
	[order] INT NOT NULL
)
GO
-- новые таблички, если ты еще их не обновлял
DROP TABLE PRICE_SCHEDULE
GO
CREATE TABLE PRICE_SCHEDULE(
	id INT PRIMARY KEY IDENTITY,
	[menu_item] INT NOT NULL,
	[dttm] DATETIME NOT NULL,
	fixed_price MONEY,
	sale INT
)
GO
-- Дополнительные таблицы
DROP TABLE PROPERTIES
GO
CREATE TABLE PROPERTIES(
	id INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(20),
	[value_int] INT,
	[value_char] VARCHAR(20)
)
GO
DROP TABLE PLACE
GO
CREATE TABLE PLACE(
	id INT PRIMARY KEY IDENTITY,
	[name] VARCHAR(20),
	[status] BIT -- 0 - счёт уже выписан, но не свободны, 1 - счёт не выписан
)
GO
insert into properties(name, value_int) values('bill', 1)