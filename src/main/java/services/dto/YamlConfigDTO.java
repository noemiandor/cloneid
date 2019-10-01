package services.dto;

import java.util.ArrayList;
import java.util.Map;

public class YamlConfigDTO {

    private Map<String, String> mysqlConnection;
    private ArrayList<String> dbTables;

    public YamlConfigDTO() {
        super();
    }

    public YamlConfigDTO(Map<String, String> mysqlConnection) {
        this.mysqlConnection = mysqlConnection;
    }

    public Map<String, String> getMysqlConnection() {
        return mysqlConnection;
    }

    public void setMysqlConnection(Map<String, String> mysqlConnection) {
        this.mysqlConnection = mysqlConnection;
    }

    public ArrayList<String> getDbTables() { return dbTables; }

    public void setDbTables(ArrayList<String> dbTables) { this.dbTables = dbTables; }

    @Override
    public String toString() {
        return "YamlConfigDTO{" +
                "mysqlConnection=" + mysqlConnection +
                ", dbTables=" + dbTables +
                '}';
    }

}
