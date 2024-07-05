/** @type {import('./$types').RequestHandler} */

import { HasMorphologyPerspective } from '@/lib/js/query/HasMorphologyPerspectiveData';

import { loadCachedFromArgs } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = true;

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
export async function GET(req) {
    const query = req.url.searchParams;
    const cellId = query.get('id');

    let status = 200;
    let rows = [];

    if (!cellId) { throw query; }

    const args = ["dbqueryhasmorphologyperspective", "HasMorphologyPerspective", cellId];
    const cached = await loadCachedFromArgs(args);

    if (fromCache && cached) {
        rows = cached;
    } else {
        if (typeof HasMorphologyPerspective == 'function') {
            // NON CACHED
            // PLACEHOLDER MODULE 3
            console.log("PLACEHOLDER MODULE 3");
            if (typeof HasMorphologyPerspective == 'function') {
                const args = [cellId];
                rows = await HasMorphologyPerspective(args)
                    .then((values) => {
                        return values;
                    })
                    .catch((e) => {
                        console.log("DBQUERYHASMORPHOLOGYPERSPECTIVE::SERVERJS::GET::ERROR::", query);
                        console.log();
                    });
                if (rows){
                    storeCached(cachedKey(args), rows);
                }
            } else {
                throw "VALUES NOT IN CACHE";
            }

        }
    }
    return jsonResponse(query, rows, status);
}