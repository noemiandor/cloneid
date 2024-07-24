<<<<<<< HEAD
// export let base = Object();
import { cellLineOrLineageId, validateCellId, validateCellLine, descendants } from './funcs.js';
//   * @param {{url: {searchParams: any;};}} req

/**
 * @param {any[]} args
 */
export async function base(args) {

    const type = args[0];
    const val = args[1];

    let data = [];

    console.log("HOMEPAGE::BASE::13::", type, val);

    switch (type) {
        case "validatecellorid": {
            let result = { 'query': type, 'date': new Date(), CellLine: null, CellId: null };
            if (val) {
                await validateCellLine(val)
                    .then((rows) => {
                        const count = rows.length;
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
                        console.log("HOMEPAGE::BASE::VALIDATECELLLINE::ERROR::", type, val, result);
                        throw e;
                    })
                ;
                await validateCellId(val)
                    .then((rows) => {
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
                    })
                    .catch((e) => {
                        console.log("HOMEPAGE::BASE::VALIDATECELLID::ERROR::", type, val, result);
                        throw e;
                    })
                ;
            }
            data.push(result);
        };
            break;

        case 'cellline': {
            data = await cellLineOrLineageId(val);
        };
            break;

        case 'tree': {
            data = await descendants([val]);
        };
            break;

        default:
            break;
    }
    if (data) return data;
    throw type + val;
}
=======
export let base = Object();
>>>>>>> master
