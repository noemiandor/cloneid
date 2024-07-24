/** @type {import('./$types').RequestHandler} */

import { timetableData } from '$lib/js/query/timetableData';
import { cachedKey, loadCachedFromArgs, storeCached } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = !true;

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
export async function GET(req) {
    const query = req.url.searchParams;
    const cellId = query.get('id');

    let status = 200;
    let rows = [];

    if (!cellId) { throw query; }

    const args = ["dbquerytimetable", "timetableData", cellId];
    const cached = await loadCachedFromArgs(args);

    if (fromCache && cached) {
        rows = cached;
    } else {
        // NON CACHED
        // PLACEHOLDER MODULE 3
        if (typeof timetableData == 'function') {
            const targs = [cellId, true];
            rows = await timetableData(targs)
                .then((values) => {
                    return values;
                })
                .catch((e) => {
                    console.log("TIMETABLE::SERVERJS::GET::ERROR::", query, e);
                    status = 500;
                })
                ;
            // TO REMOVE
            if (rows) {
                storeCached(cachedKey(args), rows);
            }
        } else {
            throw "VALUES NOT IN CACHE";
        }
    }
    return jsonResponse(query, rows, status);
}