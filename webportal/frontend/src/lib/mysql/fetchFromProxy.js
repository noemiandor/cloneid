import mysql from 'mysql2/promise';
import { count } from '../js/count';

import { SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { getShard, saveShard } from '../cache/cacheproxyfs';
import { sqlhost, sqlport } from './sqlinfo';


let connectionCount = 0

const fromShard = !true;
const toShard = true;


/**
 * @param {string} stmt
 */
export async function fetchStmtRows(stmt) {

    const result = await fetchStmt(stmt);
    return result.rows;

}

/**
 * @param {string} stmt
 */
export async function fetchStmt(stmt) {


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
        database: SQLSCHM,

        user: SQLUSER,
        password: SQLPSWD,
        connectionLimit: 5,
        queueLimit: 0
    });

    const result = await pool.getConnection()
        .then(async connection => {
            connectionCount++;

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

    return result;
}
