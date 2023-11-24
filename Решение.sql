/* Создайте таблицу  users_old, аналогичную таблице users. Создайте процедуру,
 с помощью которой можно переместить любого (одного) пользователя из таблицы users 
 в таблицу users_old. (использование транзакции с выбором commit или rollback – обязательно). */
 
DROP TABLE IF EXISTS users_old;
CREATE TABLE IF NOT EXISTS users_old SELECT * FROM users WHERE id = 0;
ALTER TABLE users_old MODIFY COLUMN id SERIAL;

DROP PROCEDURE IF EXISTS move_user;
DELIMITER $$
CREATE PROCEDURE move_user(id_p INT, OUT move_result VARCHAR(100))
DETERMINISTIC
BEGIN
	DECLARE `_rollback` BIT DEFAULT b'0';
    DECLARE code VARCHAR(100);
    DECLARE error_string VARCHAR(100);
    
    DECLARE firstname_p VARCHAR(50);
    DECLARE lastname_p VARCHAR(50);
    DECLARE email_p VARCHAR(120);
    
    DECLARE id_del INT;
    
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
		SET `_rollback` = b'1';
        GET stacked DIAGNOSTICS CONDITION 1
        code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
	END;
    
    START TRANSACTION;  
        
    SET firstname_p = (SELECT firstname FROM users u WHERE u.id = id_p);    
    SET lastname_p = (SELECT lastname FROM users u WHERE u.id = id_p);
    SET email_p = (SELECT email FROM users u WHERE u.id = id_p);
    
    SET id_del = id_p;
    
    INSERT INTO users_old (firstname, lastname, email)
    VALUES (firstname_p, lastname_p, email_p); 
    
    DELETE FROM users u WHERE u.id = id_del;
    IF `_rollback` THEN
		SET move_result = CONCAT("Ошибка ", code, " ", error_string);
        ROLLBACK;
	ELSE
		SET move_result = "OK";    
        
        COMMIT;
	END IF;        
    
END $$
DELIMITER ;
    
CALL move_user(3, @move_result);
SELECT @move_result;
SELECT * FROM users_old;
SELECT * FROM users;
    
/*Создайте хранимую функцию hello(), которая будет возвращать приветствие, 
в зависимости от текущего времени суток. С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".*/

DROP FUNCTION IF EXISTS hello;
DELIMITER $$
CREATE FUNCTION hello()
RETURNS VARCHAR(100)
DETERMINISTIC

BEGIN
	DECLARE say_hello VARCHAR(100);
    DECLARE time INT;    
    
    SET time = HOUR(CURRENT_TIMESTAMP);
    
    SELECT CASE
			WHEN time BETWEEN 0 AND 6 THEN "Доброй ночи"
            WHEN time BETWEEN 6 AND 12 THEN "Доброй утро"
            WHEN time BETWEEN 12 AND 18 THEN "Доброй день"
            WHEN time BETWEEN 18 AND 0 THEN "Доброй вечер"
	END INTO say_hello;
	RETURN say_hello;
END $$
DELIMITER ;

SELECT hello();
