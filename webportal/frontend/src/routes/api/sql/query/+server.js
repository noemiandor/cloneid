/** @type {import('./$types').RequestHandler} */

import { json } from '@sveltejs/kit';
import { validateCellLine, validateCellId } from './validateCellorId';
import { cellLineOrLineageId } from './cellLineOrLineageId';
import { findAllDescendandsOf } from './findAllDescendandsOf';
import { fetchStmt, fetchStmtRows } from '$lib/mysql/fetchFromProxy';
import { sqlhost, sqlpswd, sqluser } from '@/lib/mysql/sqlinfo';


async function processReq(method, d) {
    let data = [];
    let status = 200;

    const params = d;

    const type = d.t;
    const val = d.v;
    const user = d.u ? d.u : 'anonymous';

    process.env.SQLUSER = await sqluser(user);
    process.env.SQLPSWD = await sqlpswd(user);

    console.log(d);

    switch (type) {
        case "validatecellorid": {
            let result = { 'query': type, 'date': new Date(), CellLine: null, CellId: null };
            if (val) {
                console.log("24::SERVERJS::POST::", params, type, val, result);
                await validateCellLine(val)
                    .then((rows) => {
                        const count = rows.length;
                        console.log("24::SERVERJS::POST::", params, count, rows);
                        if (count > 0) {
                            const row = rows[0];
                            let validCellLine =
                                (row['id'] && row['cellLine'] && row['id'] == row['cellLine']);
                            if (validCellLine != true) {
                                validCellLine = false;
                            }
                            result.CellLine = validCellLine;
                        }
                    })
                    .catch((e) => {
                        console.log("24::SERVERJS::POST::ERROR::", params, type, val, result);
                        status = 500;
                        throw e;
                    })
                    ;
            }

            if (val) {
                const rows = await validateCellId(val);
                const count = rows.length;
                if (count > 0) {
                    const row = rows[0];
                    let validCellId =
                        (row['id'] && row['cellLine'] && row['id'] != row['cellLine']);
                    if (validCellId != true) {
                        validCellId = false;
                    }
                    result.CellId = validCellId;
                }
            }
            data.push(result);
        };
            break;

        case 'cellline': {
            const cellLineData = await cellLineOrLineageId(val);
            data = cellLineData.rows;
        };
            break;

        case 'cellid': {
            const cellIdData = await findAllDescendandsOf(val);
            data = cellIdData.rows;
        };
            break;

        case 'droppedfiles': {
            const flask = await fetchStmt(
                "select DISTINCT id, manufacturer, material, dishSurfaceArea_cm2, surface_treated_type, bottom_shape from CLONEID.Flask order by id asc ;"
            );

            // Get media
            const media = await fetchStmt(
                "select DISTINCT id, base1, base1_pct, base2, base2_pct, fbs, fbs_pct, energysource2, energysource2_pct, energysource, energysource_nm, hepes, hepes_mm, salt, salt_nm, antibiotic, antibiotic_pct, growthfactors, antibiotic2, antibiotic2_pct, antimycotic, antimycotic_pct, stressor, stressor_concentration, stressor_unit, comment, antibiotic3, antibiotic4, antibiotic3_pct, antibiotic4_pct from CLONEID.Media order by id asc ;"
            );
            media.rows = [{
                id: 0,
                base1: 'NULL',
                base1_pct: 0,
                base2: null,
                base2_pct: 0,
                fbs: null,
                fbs_pct: 0,
                energysource2: null,
                energysource2_pct: null,
                energysource: null,
                energysource_nm: null,
                hepes: null,
                hepes_mm: 0,
                salt: null,
                salt_nm: null,
                antibiotic: '',
                antibiotic_pct: 1,
                growthfactors: '',
                antibiotic2: '',
                antibiotic2_pct: 1,
                antimycotic: '',
                antimycotic_pct: 1,
                stressor: null,
                stressor_concentration: null,
                stressor_unit: null,
                comment: null,
                antibiotic3: null,
                antibiotic4: null,
                antibiotic3_pct: 0,
                antibiotic4_pct: 0
              }, ...media.rows];

            const eventInfo = await fetchStmt(
                `select * from Passaging where id='${val}';`
            );
            data = (
                {
                    flask: flask.rows,
                    media: media.rows,
                    event: eventInfo.rows,
                }
            )
        };
            break;

        default:
            status = 400;
            break;
    }

    return json({ "data": data, "date": new Date() }, {
        status: status,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    });
}





export async function POST({ request }) {
    const d = await request.json();
    return processReq('post', d)
}
export async function GET(request) {
    let d = {};
    for (const [k, v] of request.url.searchParams) { d[k] = v; }
    return processReq('get', d)
}
