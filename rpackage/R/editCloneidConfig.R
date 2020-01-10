editCloneidConfig = function(host = 'localhost', port = '3306', user = NA, password = NA, database="CLONEID", schemaScript = "CLONEID_schema.sql"){
    
    yaml_dir = paste0(system.file(package='cloneid'), '/config/config.yaml')
    yml = read_yaml(yaml_dir)
    
    if (is.na(host)) { host = yml$mysqlConnection$host }
    else { yml$mysqlConnection$host = host }
    
    if (is.na(port)) { port = yml$mysqlConnection$port }
    else { yml$mysqlConnection$port = port }
    
    if (is.na(user)) { user = yml$mysqlConnection$user }
    else { yml$mysqlConnection$user = user }
    
    if (is.na(password)) { password = yml$mysqlConnection$password }
    else { yml$mysqlConnection$password = password }
    
    if (is.na(database)) { database = yml$mysqlConnection$database }
    else { yml$mysqlConnection$database = database }
    
    if (is.na(schemaScript)) { schemaScript = yml$mysqlConnection$schemaScript }
    else { yml$mysqlConnection$schemaScript = schemaScript }
    
    print(yml)
    write_yaml(yml, yaml_dir)
    
}
