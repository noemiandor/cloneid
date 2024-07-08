import mysql from 'mysql2/promise';

export async function sqlupdate(table, txid) {
    try {
        const connection = await mysql.createConnection({
            host: 'sql2',
            port: 3306,
            user: 'root',
            password: 'xxxxx',
            database: 'CLONEID'
        });

        const sql = "DELETE FROM CLONEID."+table+" where transactionId=" + txid + ";";

        console.log(sql);
        const [result, fields] = await connection.query(sql);

        console.log(result);
        console.log(fields);
    } catch (err) {
        console.log(err);
    }


}