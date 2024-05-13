// import { SQLHOST, SQLPORT, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { USEDB, SQLHOST, SQLPORT, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import mysql from 'mysql2/promise';

export class sqlQuery {

    static username = '';
    static password = '';
    static host = '';
    static port = 0;
    static schema = '';
    static connectionLimit = 0;
    static queueLimit = 0;

    static connectionCount = 0
    static maxConnections = 0;

    static enabled = false;
    static wasRejected = 0;

    static useDB = (USEDB !== 'NO') ? true : false;

    static avalabilty() {
        return (sqlQuery.maxConnections - sqlQuery.connectionCount > 3);
    }

    static async debounce(query) {
        // return;
        while(sqlQuery.wasRejected>0) {
            console.log('sqlQuery.debounce::WasRejected::', sqlQuery.connectionCount);
            await new Promise(r => setTimeout(r, 500));
            if (sqlQuery.wasRejected>0) {sqlQuery.wasRejected--;}
        }
        while (!sqlQuery.avalabilty()) {
            console.log('sqlQuery.debounce::Waiting::', sqlQuery.connectionCount, query);
            await new Promise(r => setTimeout(r, sqlQuery.connectionCount*300));
        }
    }

    /**
     * @type {mysql.Pool}
     */
    static pool;

    static async createPool() {

        sqlQuery.username = SQLUSER;
        sqlQuery.password = SQLPSWD;
        sqlQuery.host = SQLHOST;
        sqlQuery.port = SQLPORT;
        sqlQuery.schema = SQLSCHM;
        sqlQuery.connectionLimit = 10;
        sqlQuery.queueLimit = 0;
        sqlQuery.connectionCount = 0
        sqlQuery.maxConnections = 8;

        sqlQuery.pool = await mysql.createPool({
            host: sqlQuery.host,
            port: sqlQuery.port,
            user: sqlQuery.username,
            password: sqlQuery.password,
            database: sqlQuery.schema,
            connectionLimit: sqlQuery.connectionLimit,
            queueLimit: sqlQuery.queueLimit,
        });

        sqlQuery.enabled = true;

        return sqlQuery.pool;
    }

    /**
     * @param {string} query
     */
    static async fetchStmt(query) {
        if (!sqlQuery.useDB) {
            return [];
        }
        if (!sqlQuery.enabled){
            await sqlQuery.createPool();
        }
        await sqlQuery.debounce(query)
        return await sqlQuery.pool.getConnection()
            .then(async connection => {
                sqlQuery.connectionCount++;
                const [rows, fields] = await connection.query(query);
                await connection.release();
                await connection.destroy();
                await sqlQuery.pool.releaseConnection(connection);
                sqlQuery.connectionCount--;
                if (!sqlQuery.avalabilty) {
                    console.log('fetchstmt::', sqlQuery.connectionCount, Array(rows).length);
                }
                return {
                    "date": new Date(),
                    "connections": sqlQuery.connectionCount,
                    "error": "",
                    "rows": rows,
                    "fields": fields
                };
            },
            async (reject)=>{
                    console.log("sqlQuery::fetchstmt::reject", reject);
                    await new Promise(r => setTimeout(r, 2000));
            })
            .catch(async err => {
                console.log("sqlQuery::fetchstmt::catch", err);
                await new Promise(r => setTimeout(r, 2000));
                throw { "description": "Mysql createpool.getconnection", "error": err, "connections:": sqlQuery.connectionCount, "rows": [] };
            })
            ;
    }
}
