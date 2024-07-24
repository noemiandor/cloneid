import mysql from 'mysql2/promise';
import { count } from '../js/count';

<<<<<<< HEAD
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
=======
import { SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { getShard, saveShard } from '../cache/cacheproxyfs';
import { sqlhost, sqlport } from './sqlinfo';


let connectionCount = 0

const fromShard = !true;
const toShard = true;

>>>>>>> master

/**
 * @param {string} stmt
 */
export async function fetchStmtRows(stmt) {

<<<<<<< HEAD
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
=======
    const result = await fetchStmt(stmt);
    return result.rows;

>>>>>>> master
}

/**
 * @param {string} stmt
 */
export async function fetchStmt(stmt) {

<<<<<<< HEAD
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
=======

    var sqluser   = process.env.SQLUSER;
    var sqlpswd   = process.env.SQLPSWD;

    if (fromShard) {
        const cached = await getShard(stmt);
        if (cached && cached!==null && count(cached.rows) > 0) {
            return cached;
        } else {
            console.log("FETCHFROMPROXY::FETCHSTMT::FROMSHARD::NOT CACHED::", stmt, count(cached));
        }
    }

    const pool = await mysql.createPool({
        host: sqlhost(),
        port: parseInt(sqlport()),
>>>>>>> master
        database: SQLSCHM,

        user: SQLUSER,
        password: SQLPSWD,
        connectionLimit: 5,
        queueLimit: 0
    });

    const result = await pool.getConnection()
        .then(async connection => {
            connectionCount++;
<<<<<<< HEAD
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
=======

            return await connection.query(stmt)
                .then(([rows, _fields]) => {
                    connection.release();
                    pool.releaseConnection(connection);
                    connection.destroy();
                    connectionCount--;
                    if (rows) {
                        const fields = _fields.map((x)=>{
                            return({
                                "characterSet": x.characterSet,
                                "encoding": x.encoding,
                                "name": x.name,
                                "columnLength": x.columnLength,
                                "columnType": x.columnType,
                                "type": x.type,
                                "flags": x.flags,
                                "decimals": x.decimals,
                            })
                        });
                        const qinfo = {
                            "date": new Date(),
                            "connections": connectionCount,
                            "rows": rows,
                            "fields": fields
                        };
                        if (rows.length>0 && toShard) {
                            saveShard(stmt, qinfo);
                        }
                        return qinfo;
                    }
                    throw stmt;
                })
        })
        .catch(err => {
            connectionCount--;
            console.log("fetchFromProxy::fetchstmt::catch", err);
            return  { error: err.sqlMessage}
        })
        ;

>>>>>>> master
    return result;
}
