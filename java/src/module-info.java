module java {
	exports core;
	exports database;
	exports core.utils;
	exports useri;
	exports useri.utils;

	requires java.sql;
	requires mysql.connector.java;
}