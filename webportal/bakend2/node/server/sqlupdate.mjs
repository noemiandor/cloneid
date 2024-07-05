import { createConnection } from 'mysql';


export function sqlupdate(txid) {

    let connection = createConnection({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
    });
    connection = createConnection({
        host: 'sql2',
        port: 3306,
        user: 'root',
        password: 'xxxxx',
        database: 'CLONEID'
    });

    connection.connect((err) => {
        if (err) return console.error(err.message);


        let data = [false, 1];

        let sql = "DELETE FROM CLONEID.Passaging where transactionId = " + transactionId + " ;";
        data = [txid];

        connection.query(sql, data, (error, results, fields) => {
            if (error) return console.error(error.message);
            console.log('Rows affected:', results.affectedRows);
        });

        connection.end();
    });
}