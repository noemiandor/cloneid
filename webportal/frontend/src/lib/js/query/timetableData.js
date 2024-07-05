// export let timetableData = Object();
import { fetchStmtRows } from '$lib/mysql/fetchFromProxy';

/**
 * @param {number} distance
 */
function timeDistance(distance) {
    const days = Math.floor(distance / (24 * 3600000));
    distance -= days * (24 * 3600000);
    const hours = Math.floor(distance / 3600000);
    distance -= hours * 3600000;
    const minutes = Math.floor(distance / 60000);
    distance -= minutes * 60000;
    const seconds = Math.floor(distance / 1000);
    return days > 0 ?
        `${days}d${('0' + hours).slice(-2)}h${('0' + minutes).slice(-2)}m`
        : (
            hours > 0 ?
                `${('0' + hours).slice(-2)}h${('0' + minutes).slice(-2)}m`
                :
                `${('0' + minutes).slice(-2)}m`
        );
};

/**
* @param {{ [s: string]: any; } } x
*/
function sanityze(x) {
    let nullRemoved = {};
    Object.entries(x).forEach(([k, v]) => {
        if (v != undefined && v != null) {
            if (k.toLowerCase() === 'date') {
                nullRemoved[k] = new Date(v);
            } else {
                nullRemoved[k] = v;
            }
        }
    }
    );
    return nullRemoved;
}

/**
 * @param {any[]} args
 */
export async function timetableData(args) {
    const ids = args[0];
    const recurse = args[1];

    /**
     * @type {{ i: any; p: any; d: any; }[]}
     */
    let leaves = [];
    let ileaves = {};
    let branches = {};

    /**
     * @param {any[]} branch
     * @param {number} start
     */
    function minMaxDuration(branch, start) {
        let max = Number.NEGATIVE_INFINITY
        let min = Number.POSITIVE_INFINITY

        min = start;

        branch.forEach((harvest) => {
            min = Math.min(min, harvest.date.getTime());
            max = Math.max(max, harvest.date.getTime());
        });

        let duration = Math.abs(max - min);
        const d1 = new Date();
        const d2 = new Date();
        d1.setTime(min);
        d2.setTime(max);
        let dhms = timeDistance(duration);
        if (duration === Number.POSITIVE_INFINITY) {
            d1.setTime(min);
            d2.setTime(min);
            duration = 0;
            dhms=d1.toDateString();
            dhms="|";
            }
        return { "start": d1, "end": d2, "duration": duration, "dhms": dhms };
    }

    /**
     * @param {any} parent
     */
    async function spreadLeaves(parent, recurse = true) {

        const stmt = `select * from Passaging where passaged_from_id1='${parent}';`;

        const kids = await fetchStmtRows(stmt)
            .then((rows) => {
                return rows.map((row) => { return { id: row.id, row: sanityze(row) }; });
            }
            )
            .catch((e) => {
                console.log('findAllDescendandsOf::spreadLeaves::kids::ERROR', stmt, e);
            });

        for (let i in kids) {
            const kid = kids[i];
            const leave = ({ "i": kid.id, "p": kid.row.passaged_from_id1, "d": kid.row });
            leaves.push(leave);
            ileaves[kid.id] = leave;
        }

        if (recurse) {
            for (const kid of kids) {
                const k2 = await spreadLeaves(kid.id);
            }
        }
    }

    function setBranches() {
        leaves.forEach((leave) => {
            if (
                leave.d.event == "seeding"
            ) {
                if (branches[leave.i] == undefined) {
                    branches[leave.i] = [];
                }
            }
        });
    }

    function growBranches() {
        leaves.forEach((leave) => {
            if (
                leave.d.event == "harvest"
            ) {
                if (branches[leave.p] == undefined) {
                    branches[leave.p] = [];
                }
                branches[leave.p].push(leave.d);
            }
        });
    }

    function growTree() {
        setBranches();
        growBranches();
    }

    async function findParents() {

        const idsArray = ids.split(',').map(id => id.trim());
        const stmt = `select * from Passaging where id in ( ${idsArray.map(id => `'${id}'`).join(', ')} ) order by date DESC;`;
        const parents = await fetchStmtRows(stmt);
        if (parents.length <= 0) {
            throw ids
        }
        for (let parent of parents) {
            const leave = ({ "i": parent.id, "p": parent.id, "d": sanityze(parent) });
            leaves.push(leave);
            ileaves[parent.id] = leave;
            await spreadLeaves(parent.id, recurse);
        }
    }

    function calculateDurations() {
        /**
         * @type {{ start: Date; end: Date; duration: number; dhms: string; }[]}
         */
        let durations = [];
        const bk = Object.keys(branches);
        for (const k of bk) {
            const v = branches[k];
            const l = ileaves[k];
            let duration = minMaxDuration(v, l.d.date);
            duration.seed = k;
            durations.push(duration);
        }
        return durations;
    }

    await findParents();
    growTree();
    const durations = calculateDurations();
    return durations;
}