import { json } from '@sveltejs/kit';

// API/DB/QUERY/*

/**
 * @param {any} query
 * @param {any} rows
 * @param {number} status
 */
export async function jsonResponse(query, rows, status) {

    if (!rows) { throw query; }

    return json(
        {
            "data": rows,
            "date": new Date()
        },
        {
            status: status,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    );
}