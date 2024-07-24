/** @type {import('./$types').RequestHandler} */

<<<<<<< HEAD
import { SQLHOST, SQLPORT, SQLSCHM } from '$env/static/private';
import mysql from 'mysql2/promise';

/**
 * Authenticate a user with the given username and password.
 * @param {string} username - The username of the user to authenticate.
 * @param {string} password - The password of the user to authenticate.
 * @returns {Promise<number>} A promise that resolves to 1 if authenticated, -1 otherwise.
 */
async function authenticateUser(username, password) {
    let ret = 0;
    // Create a new connection pool with the user credentials and attempt to get a connection
    await mysql.createPool({
        host: SQLHOST,             // Database host
        port: parseInt(SQLPORT),   // Database port, converted to an integer
        database: SQLSCHM,         // Database schema name
        user: username,            // Username for authentication
        password: password,        // Password for authentication
        connectionLimit: 10,       // Maximum number of connections in the pool
        queueLimit: 0,             // Maximum number of queue requests (0 for no limit)
        waitForConnections: true,  // Wait for connections if none are available
    }).getConnection()
        .then((connection) => {
            ret = 1;               // Set return value to 1 if connection is successful
            connection.release();   // Release the connection back to the pool
        },
            () => {
                ret = -1;          // Set return value to -1 if connection fails
            })
        .catch(() => {
            ret = -1;              // Set return value to -1 on any other error
        });
    return ret;                    // Return the result of the authentication attempt
}

// Exported POST method to handle incoming HTTP POST requests
export async function POST({ request }) {
    const { userName, passWord } = await request.json(); // Extract username and password from the request body
    let ret = false; // Variable to store the success status of the operation
    let status = 200; // HTTP status code to be returned

    // Call the authenticateUser function and process the result
    await authenticateUser(userName, passWord)
        .then(function (value) {
            if (value > 0) {
                ret = true; // Authentication successful
            } else if (value == 0) {
                ret = false; // Authentication not attempted or failed
            } else {
                status = 401; // Unauthorized access, set status to 401
                ret = false; // Authentication failed
            }
        })
        .catch((e) => {
            status = 500; // Internal server error, set status to 500
            ret = false; // Authentication failed
            throw e; // Re-throw the caught exception
        });

    // Return the response with the outcome of the authentication and the HTTP status code
    return new Response(
        JSON.stringify({
=======
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
>>>>>>> master
            'sql': ret,
            'status': status
        }), {
        status: status
    });
}