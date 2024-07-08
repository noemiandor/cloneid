import mysql from 'mysql2/promise';
import { count } from '../js/count';

import { getShard, saveShard } from '../cache/cacheproxyfs';
import { USEDB, USECACHE, SQLHOST, SQLPORT, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';

let connectionCount = 0

let useDB = (USEDB !== 'NO') ? true : false;
let useCache = (USECACHE !== 'NO') ? true : false;

let fromShard = useCache?true:false;
let toShard = useCache?true:false;

if (false) {
    useDB = true;
    useCache = false;
    fromShard = false;
    toShard = false;
}

/**
 * @param {string} stmt
 */
export async function fetchStmtRows(stmt) {

    if (fromShard) {
        const cachedRows = await getShard(stmt);
        if (cachedRows && count(cachedRows) > 0) {
            return cachedRows;
        }
    }

    if (!useDB) {
        return [];
    }
    
    const pool = mysql.createPool({
        host: SQLHOST,
        port: parseInt(SQLPORT),
        database: SQLSCHM,

        user: SQLUSER,
        password: SQLPSWD,
        connectionLimit: 5,
        queueLimit: 0
    });

    return await pool.getConnection()
        .then(async connection => {
            connectionCount++;
            return await connection.query(stmt)
                .then(([rows, fields]) => {
                    connection.release();
                    pool.releaseConnection(connection);
                    connection.destroy();
                    connectionCount--;
                    if (rows) {
                        if (useDB && toShard) {
                            saveShard(stmt, rows);
                        }
                        return rows;
                    }
                    throw stmt;
                })
        })
        .catch(err => {
            connectionCount--;
            console.log("fetchFromProxy::fetchstmt::catch", err.errno);
            // throw stmt;
        })
        ;
}

/**
 * @param {string} stmt
 */
export async function fetchStmt(stmt) {

    if (fromShard) {
        const cachedRows = await getShard(stmt);
        if (cachedRows && count(cachedRows) > 0) {
            return cachedRows;
        }
    }

    if (!useDB) {
        return [];
    }

    const pool = await mysql.createPool({
        host: SQLHOST,
        port: parseInt(SQLPORT),
        database: SQLSCHM,

        user: SQLUSER,
        password: SQLPSWD,
        connectionLimit: 5,
        queueLimit: 0
    });

    const result = await pool.getConnection()
        .then(async connection => {
            connectionCount++;
            const [rows, fields] = await connection.query(stmt);
            await connection.release();
            await pool.releaseConnection(connection);
            await connection.destroy();
            connectionCount--;
            return { "rows": rows };
        })
        .catch(err => {
            console.log("fetchFromProxy::fetchstmt::catch", err.errno);
        })
        ;

    if (useDB && toShard) {
        saveShard(stmt, result.rows);
    }
    return result;
}
