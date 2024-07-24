// export let timetableData = Object();
import { fetchStmtRows } from '$lib/mysql/fetchFromProxy';
<<<<<<< HEAD
=======
import { descendants } from './funcs';
>>>>>>> master

/**
 * @param {number} distance
 */
function timeDistance(distance) {
<<<<<<< HEAD
=======
    // export const timeDistance = (date1, date2) => {
    //     let distance = Math.abs(date1 - date2);
>>>>>>> master
    const days = Math.floor(distance / (24 * 3600000));
    distance -= days * (24 * 3600000);
    const hours = Math.floor(distance / 3600000);
    distance -= hours * 3600000;
    const minutes = Math.floor(distance / 60000);
    distance -= minutes * 60000;
    const seconds = Math.floor(distance / 1000);
<<<<<<< HEAD
=======
    // return `${days}:${hours}:${('0' + minutes).slice(-2)}:${('0' + seconds).slice(-2)}`;
    // return `${days}d${hours}h${('0' + minutes).slice(-2)}m${('0' + seconds).slice(-2)}s`;
>>>>>>> master
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
<<<<<<< HEAD
                nullRemoved[k] = new Date(v);
=======
                nullRemoved[k] = new Date(v); //Date.parse(v);
>>>>>>> master
            } else {
                nullRemoved[k] = v;
            }
        }
<<<<<<< HEAD
=======
        // console.log("k:v", k, v);
>>>>>>> master
    }
    );
    return nullRemoved;
}

<<<<<<< HEAD
=======
// la1=findAllDescendandsOf(id="KATOIII_A5_seed");
// la2=la1[la1$event=="seeding",]
// la3=sapply(la2$id, function(x) findAllDescendandsOf(id=x, recursive=F), simplify=F)
// la4=sapply(la3, function(x) quantile(as.POSIXct(x$date), c(0,1)),simplify=F)
// ## This comes closer to what we want:
// barplot(sapply(la4, function(x) x[2]-x[1]))

>>>>>>> master
/**
 * @param {any[]} args
 */
export async function timetableData(args) {
    const ids = args[0];
    const recurse = args[1];

<<<<<<< HEAD
=======



    //     const descendantsOf = await descendants([ids]);
    //     const originList = descendantsOf.map((x) => { return x.id.toString(); }); //.join(",");
    //     const seedingEvents = descendantsOf.filter((x) => { return x.event === 'seeding' ; } ).map((x) => { return x.id.toString(); });
    //     let seedingWithDescendants = [];
    //     // console.log(`timetableData::descendantsOf::70::(${args}, ${ids})`, originList.length, originList, seedingEvents);
    //     seedingEvents.forEach(async (x)=>{
    //         const seedingDescendants = await descendants([x, false]);
    //         const seedingDescendantsIds = seedingDescendants.map((x) => { return x.id.toString(); });
    //         const seedingDescendantsDates = seedingDescendants.map((x) => { return x.date; });
    //         // seedingWithDescendants[x] = await descendants([x]);
    //         seedingWithDescendants[x] = seedingDescendantsDates;
    //     console.log(`timetableData::descendantsOf::74::`, x, seedingDescendants.length, seedingDescendantsIds, seedingDescendantsDates );
    //     })
    //     // console.log(`timetableData::descendantsOf::74::`, seedingWithDescendants.length, seedingWithDescendants );


    // return;

>>>>>>> master
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
<<<<<<< HEAD
=======
        // let max = -1
>>>>>>> master
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
<<<<<<< HEAD
=======
        // console.log(d1, d2, duration, s);
        // return [d1, d2, duration, s];
        // if(duration ===  Number.POSITIVE_INFINITY){
        //     const dhms = timeDistance(0.00000001);
        //     // return duration;
        //     return { "start": d1, "end": d2, "duration":0.00000001, "dhms": dhms };

        // }else{
>>>>>>> master
        let dhms = timeDistance(duration);
        if (duration === Number.POSITIVE_INFINITY) {
            d1.setTime(min);
            d2.setTime(min);
            duration = 0;
            dhms=d1.toDateString();
            dhms="|";
            }
<<<<<<< HEAD
        return { "start": d1, "end": d2, "duration": duration, "dhms": dhms };
=======
        // return duration;
        return { "start": d1, "end": d2, "duration": duration, "dhms": dhms };

        // }
>>>>>>> master
    }

    /**
     * @param {any} parent
     */
    async function spreadLeaves(parent, recurse = true) {

        const stmt = `select * from Passaging where passaged_from_id1='${parent}';`;

        const kids = await fetchStmtRows(stmt)
            .then((rows) => {
<<<<<<< HEAD
                return rows.map((row) => { return { id: row.id, row: sanityze(row) }; });
            }
            )
            .catch((e) => {
                console.log('findAllDescendandsOf::spreadLeaves::kids::ERROR', stmt, e);
            });

        for (let i in kids) {
            const kid = kids[i];
=======
                // console.log('findAllDescendandsOf::spreadLeaves::kids::DATA', rows, stmt);
                return rows.map((row) => { return { id: row.id, row: sanityze(row) }; });
            }
                // else {
                //     console.log('findAllDescendandsOf::spreadLeaves::kids::ERROR', stmt);
                //     console.log();
                //     throw stmt;
                // }
            )
            .catch((e) => {
                console.log('findAllDescendandsOf::spreadLeaves::kids::ERROR', stmt, e);
                console.log();
            });

        // console.log('findAllDescendandsOf::spreadLeaves::kids::LENGTH', kids.length);

        for (let i in kids) {
            const kid = kids[i];
            // console.log('findAllDescendandsOf::spreadLeaves::kids::i::kid', i, kid);
>>>>>>> master
            const leave = ({ "i": kid.id, "p": kid.row.passaged_from_id1, "d": kid.row });
            leaves.push(leave);
            ileaves[kid.id] = leave;
        }

<<<<<<< HEAD
=======
        // kids.forEach((/** @type {{ id: any; row: any; }} */ kid) => {
        //     const leave = ({ "i": kid.id, "p": kid.row.passaged_from_id1, "d": kid.row });
        //     leaves.push(leave);
        //     ileaves[kid.id] = leave;
        // });

>>>>>>> master
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
<<<<<<< HEAD
        if (parents.length <= 0) {
=======
        // console.log('findAllDescendandsOf', stmt, parents);
        if (parents.length <= 0) {
            console.log('findAllDescendandsOf THROWING', ids);
>>>>>>> master
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
<<<<<<< HEAD
        const bk = Object.keys(branches);
        for (const k of bk) {
            const v = branches[k];
            const l = ileaves[k];
            let duration = minMaxDuration(v, l.d.date);
            duration.seed = k;
            durations.push(duration);
        }
=======
        // Object.entries(branches).forEach(([k, v]) => {
        //     const l = ileaves[k];
        //     let duration = minMaxDuration(v, l.d.date);
        //     // duration["seed"] = k;
        //     duration.seed = k;
        //     durations.push(duration);
        //     console.log('duration:', duration);
        // });
        const bk = Object.keys(branches);
        // console.log('bk:', bk);
        for (const k of bk) {
            const v = branches[k];
            // console.log('k:v', k,v);
            const l = ileaves[k];
            // if (v.length<1) continue;
            let duration = minMaxDuration(v, l.d.date);
            // duration["seed"] = k;
            duration.seed = k;
            durations.push(duration);
            // console.log('duration:', duration);
        }
        // Object.entries(branches).forEach(([k, v]) => {
        //     const l = ileaves[k];
        //     let duration = minMaxDuration(v, l.d.date);
        //     // duration["seed"] = k;
        //     duration.seed = k;
        //     durations.push(duration);
        //     console.log('duration:', duration);
        // });
        // console.log('durations:', durations);
>>>>>>> master
        return durations;
    }

    await findParents();
    growTree();
<<<<<<< HEAD
    const durations = calculateDurations();
=======
    // console.log('leaves:', leaves);
    // console.log('branches:', branches);
    const durations = calculateDurations();
    // console.log('duration:', durations);
>>>>>>> master
    return durations;
}