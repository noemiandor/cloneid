package services;

import org.apache.ibatis.jdbc.ScriptRunner;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.Reader;
import java.sql.*;
import java.io.File;
import java.net.URISyntaxException;
import java.util.ArrayList;
import org.apache.commons.io.FilenameUtils;

public class DatabaseService {

    private static final String DROP_DATABASE = "DROP DATABASE IF EXISTS ";
    private static final String CREATE_DATABASE = "CREATE DATABASE IF NOT EXISTS ";
    private static final String STDERR_PREFIX = "JAVADB: ";
    private static final String NO_CHANGES_MADE_TO_DB = "No changes were made to database: ";
    private static final String RECREATE_DATABASE_WARNING = STDERR_PREFIX + "If you would like to drop the database and recreate "
        + "the schema please run \'createCloneidSchema(forceCreateSchema = TRUE)\'\n";

    private String host;
    private String port;
    private String db_url_create_db;
    private String db_url_create_schema;
    private String username;
    private String password;
    private String database;
    private String createSchemaScriptDir;
    private ArrayList<String> dbTables;
    private Boolean forceCreateSchema;

    public DatabaseService(String host, String port, String username, String password, String database,
                           String createSchemaScriptDir, ArrayList<String> dbTables, Boolean forceCreateSchema)
    {
        this.host = host;
        this.port = port;
        this.username = username;
        this.password = password;
        this.database = database;
        this.createSchemaScriptDir = createSchemaScriptDir;
        this.dbTables = dbTables;
        this.forceCreateSchema = forceCreateSchema;
        setDbUrl(host, port);
    }

    public void setDbUrl(String host, String port) {
        this.db_url_create_db = "jdbc:mysql://" + host + ':' + port + "?serverTimezone=UTC";
        this.db_url_create_schema = "jdbc:mysql://" + host + ':' + port + "/" + database + "?serverTimezone=UTC";
    }

    public String getHost() {
        return host;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public String getPort() {
        return port;
    }

    public void setPort(String port) {
        this.port = port;
    }

    public void createSchema() throws Exception {

        final String SQL_DIR = "../sql/" + createSchemaScriptDir;
        Boolean databaseExists;
        Boolean tablesExist;

        try {
            String pth = new File(DatabaseService.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getPath();
            pth = FilenameUtils.getFullPath(pth);

            File sqlScriptFile = new File(createSchemaScriptDir);
            if (!sqlScriptFile.exists()) {
                createSchemaScriptDir = pth + SQL_DIR;
            }

        } catch (URISyntaxException u) {
            System.err.println(STDERR_PREFIX + "SQL script not found");
            System.exit(1);
        }

        Connection connect = DriverManager.getConnection(db_url_create_db, username, password);

        if (forceCreateSchema) {
            connect.createStatement().executeUpdate(DROP_DATABASE + database);
        }

        databaseExists = checkIfDatabaseExists(connect);
        tablesExist = checkIfTablesExist(connect);

        if (!databaseExists && !tablesExist) {

            connect.createStatement().executeUpdate(CREATE_DATABASE + database);
            connect = DriverManager.getConnection(db_url_create_schema, username, password);

            ScriptRunner sRunner = new ScriptRunner(connect);
            Reader reader = new BufferedReader(new FileReader(createSchemaScriptDir));

            try {
                sRunner.runScript(reader);
                System.out.println(STDERR_PREFIX + "** CLONEID Schema created successfully **\n");
            } catch (Exception e) {
                System.out.println(STDERR_PREFIX + "Unable to run SQL script");
            }

        } else {
            System.err.println(STDERR_PREFIX + NO_CHANGES_MADE_TO_DB + database);
        }

        connect.close();
    }

    private Boolean checkIfDatabaseExists(Connection connect) {

        String existingDatabase;

        try {
            ResultSet rs = connect.getMetaData().getCatalogs();

            while (rs.next()) {
                existingDatabase = rs.getString(1);
                if (existingDatabase.equals(database)) {
                    System.err.println(STDERR_PREFIX + "ATTENTION: Database exists: " + database);
                    return true;
                }
            }

        } catch (SQLException e) {
            System.out.println(STDERR_PREFIX + e);
        }

        return false;

    }

    private Boolean checkIfTablesExist(Connection connect) {

        class Table {
            public String table;
            public Boolean isEmpty;
        }

        ArrayList<String> errors = new ArrayList<>();
        ArrayList<Table> existingTables = new ArrayList<>();
        Boolean atLeastOneTableExists = false;
        Boolean emptyResultSet;

        for (String table : dbTables) {

            try {

                Table tableIsEmpty = new Table();

                ResultSet rs = connect.createStatement().executeQuery("select * from " + database + '.' + table + " limit 1");
                emptyResultSet = !rs.next();
                tableIsEmpty.table = table;

                if (!emptyResultSet) {
                    tableIsEmpty.isEmpty = false;
                } else {
                    tableIsEmpty.isEmpty = true;
                }

                existingTables.add(tableIsEmpty);
                atLeastOneTableExists = true;

            } catch (SQLSyntaxErrorException e) {
                errors.add(e.getMessage());
            } catch (SQLException e) {
                System.out.println(STDERR_PREFIX + e.getMessage());
            }

        }

        if (!existingTables.isEmpty()) {
            for (Table table : existingTables) {
                System.err.println(STDERR_PREFIX + "ATTENTION: Table exists: " + table.table + " (isEmpty: " + table.isEmpty + ')');
            }
        }

        if (!errors.isEmpty() && atLeastOneTableExists) {
            System.err.println();
            for (String err : errors) {
                System.err.println(STDERR_PREFIX + "WARNING: " + err);
            }
        }

        if (atLeastOneTableExists && !forceCreateSchema) {
            System.err.println(RECREATE_DATABASE_WARNING);
        }

        return atLeastOneTableExists;
    }

}
