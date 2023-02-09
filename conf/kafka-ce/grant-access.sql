GRANT ALL ON *.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

CREATE USER 'mysqluser'@'localhost' IDENTIFIED BY 'mysqlpw';
GRANT ALL ON *.* TO 'mysqluser'@'localhost';
GRANT ALL ON *.* TO 'mysqluser'@'%';
FLUSH PRIVILEGES;