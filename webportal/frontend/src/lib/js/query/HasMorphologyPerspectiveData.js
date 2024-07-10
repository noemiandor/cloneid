// export let HasMorphologyPerspective = Object();
// export let HasMorphologyPerspective = Object();
import { fetchStmtRows } from '$lib/mysql/fetchFromProxy';

/**
 * @param {any[]} args
 */
export async function HasMorphologyPerspective(args) {
    const id = args[0];
    // return await fetchStmtRows(`SELECT origin, cloneID from MorphologyPerspective where parent IS NULL AND hasChildren=true AND sampleSource='${id}' AND whichPerspective='MorphologyPerspective' ORDER BY size DESC;`);
    return await fetchStmtRows(`SELECT origin, cloneID from Perspective where parent IS NULL AND hasChildren=true AND sampleSource='${id}' AND whichPerspective='MorphologyPerspective' ORDER BY size DESC;`);
}
