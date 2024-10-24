import { fetchStmt, fetchStmtRows } from '$lib/mysql/fetchFromProxy';


/**
 * @param {string} val
 */
export async function validateCellLine(val) {
    const cellline = await fetchStmtRows(`select id, cellLine, count(*) as count from Passaging where id IN ('${val}') and id=cellLine;`);
<<<<<<< HEAD
    return cellline;
=======
    // console.log("FUNCS::VALIDATECELLLINE::", cellline);
    return cellline;
    if (cellline) return cellline;
    throw val;
    process.abort();
>>>>>>> master
}

/**
 * @param {string} val
 */
export async function validateCellId(val) {
    const celllid = await fetchStmtRows(`select id, cellLine, count(*) as count from Passaging where id IN ('${val}') and id!=cellLine;`);
<<<<<<< HEAD
    if (celllid) return celllid;
=======
    // console.log("FUNCS::VALIDATECELLLID::", celllid);
    if (celllid) return celllid;
    throw val;
    process.abort();
>>>>>>> master
}

/**
 * @param {string} id
 */
export async function cellLineOrLineageId(id) {
    const rows = await fetchStmtRows(`SELECT id,passage,cellLine,event,passaged_from_id1 FROM Passaging WHERE cellLine='${id}' ORDER BY passage ASC;`);
<<<<<<< HEAD
=======
    // console.log("FUNCS::CELLLINEORLINEAGEID::", rows);
>>>>>>> master
    return rows;
}






/**
 * @param {any[]} args
 */
export async function descendants(args, mydb = null, recursive = true, verbose = true) {
    const ids = args[0];
<<<<<<< HEAD
=======
    // const mydb = null, recursive = true, verbose = true;
>>>>>>> master
    /**
        * @param {string} stmt
        * @returns {Promise<string[]>}
        */
    async function execute(stmt) {
        return await fetchStmtRows(stmt)
            .then((rows) => {
                return rows.filter((/** @type {string} */ id) => id !== "").map((/** @type {{ id: string; }} */ row) => row);
            });
    }
    const idList = args.map(id => `'${id}'`).join(', ');
    const stmt = `SELECT * FROM Passaging WHERE id IN (${idList}) ORDER BY date DESC`;
    const rows = await execute(stmt);


    async function traceDescendants2(x) {
        const idList = x.map(id => `'${id}'`).join(', ');
        const stmt = `SELECT * FROM Passaging WHERE passaged_from_id1 IN (${idList}) `;
        const kids = await execute(stmt);
        if (kids.length) {
            let out = kids.map(kid => kid.id);

            if (recursive) {
<<<<<<< HEAD
                out = out.concat(await traceDescendants2(out));
=======
                // for (const kid of kids) {
                out = out.concat(await traceDescendants2(out));
                // }
>>>>>>> master
            }

            return out;
        }
        return [];
    }

    let allLineages = [];
    const out = {};

    for (const parent of rows) {
        const descendants = [parent.id, ...(await traceDescendants2([parent.id]))];
        const filteredDescendants = descendants.filter(descendant => !allLineages.includes(descendant));
<<<<<<< HEAD
        allLineages = allLineages.concat(filteredDescendants);
        const descendantsString = filteredDescendants.map(descendant => `'${descendant}'`).join(', ');
=======

        allLineages = allLineages.concat(filteredDescendants);
        const descendantsString = filteredDescendants.map(descendant => `'${descendant}'`).join(', ');

>>>>>>> master
        out[parent.id] = `SELECT *, '${parent.id}' AS Ancestor FROM Passaging WHERE id IN (${descendantsString})`;
    }

    const statements = Object.values(out);
    const unionStmt = statements.join(' UNION ');

<<<<<<< HEAD
=======
    // if (verbose) {
    //     console.log(unionStmt);
    // }

>>>>>>> master
    return await execute(unionStmt);

}