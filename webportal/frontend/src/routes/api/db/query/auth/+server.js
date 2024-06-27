/** @type {import('./$types').RequestHandler} */

import { SQLSCHM } from '$env/static/private';
import { sqlhost, sqlport } from '@/lib/mysql/sqlinfo';
import { createUser } from '@/lib/mysql/sqluser';
import mysql from 'mysql2/promise';

/**
 * @param {string} username
 * @param {string} password
 */
async function authenticateUser(username, password) {
    let ret = 0;
    await mysql.createPool({
        host: sqlhost(),
        port: parseInt(sqlport()),
        database: SQLSCHM,
        user: username,
        password: password,
        connectionLimit: 10,
        queueLimit: 0,
        waitForConnections: true,
    }).getConnection()
        .then((connection) => {
            ret = 1;
            createUser(username,password);
            connection.release();
        },
            () => {
                ret = -1;
            })
        .catch(() => {
            ret = -1;
        })
        ;
    return ret;
}

export async function POST({ request }) {
    const { userName, passWord } = await request.json();
    let ret = false;
    let status = 200;
    await authenticateUser(userName, passWord)
        .then(function (value) {
            if (value > 0) {
                ret = true;
            } else if (value == 0) {
                ret = false;
            } else {
                status = 503;
                ret = false;
            }
        })
        .catch((e) => {
            status = 500;
            ret = false;
            throw e;
        })
        ;
    return new Response(
        JSON.stringify({
            'auth': ret,
            'sql': ret,
            'status': status
        }), {
        status: status
    });
}