/** @type {import('./$types').RequestHandler} */

import { HasMorphologyPerspective } from '@/lib/js/query/HasMorphologyPerspectiveData';

<<<<<<< HEAD
import { loadCachedFromArgs } from '@/lib/cache/cacheproxyfs';
=======
import { cachedKey, loadCachedFromArgs, storeCached } from '@/lib/cache/cacheproxyfs';
import { count } from '@/lib/js/count';
>>>>>>> master
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
<<<<<<< HEAD
=======
    const key = cachedKey(args);
>>>>>>> master
    const cached = await loadCachedFromArgs(args);

    if (fromCache && cached) {
        rows = cached;
    } else {
<<<<<<< HEAD
        if (typeof HasMorphologyPerspective == 'function') {
=======
>>>>>>> master
            // NON CACHED
            // PLACEHOLDER MODULE 3
            console.log("PLACEHOLDER MODULE 3");
            if (typeof HasMorphologyPerspective == 'function') {
                const args = [cellId];
                rows = await HasMorphologyPerspective(args)
                    .then((values) => {
<<<<<<< HEAD
=======
                        if (values) {
                            storeCached(cachedKey(args), values);
                        }
                        console.log("HASMORPHOLOGYPERSPECTIVE::HASMORPHOLOGYPERSPECTIVE::", values);
>>>>>>> master
                        return values;
                    })
                    .catch((e) => {
                        console.log("DBQUERYHASMORPHOLOGYPERSPECTIVE::SERVERJS::GET::ERROR::", query);
                        console.log();
                    });
<<<<<<< HEAD
                if (rows){
                    storeCached(cachedKey(args), rows);
                }
=======
>>>>>>> master
            } else {
                throw "VALUES NOT IN CACHE";
            }

<<<<<<< HEAD
        }
=======
>>>>>>> master
    }
    return jsonResponse(query, rows, status);
}