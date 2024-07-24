import { GenomePerspective } from '../GenomePerspective';
import { Identity } from '../Identity';
import { Perspectives } from './Perspectives';
import { TranscriptomePerspective } from '../TranscriptomePerspective';
import { MorphologyPerspective } from '../MorphologyPerspective';

/**
 * @param {number} size - the size of the clone relative to the biosample
 * @param {string} sampleName - the name of the biosample
 * @param {Perspectives} which - the perspective from which this clone is viewed or NULL, if we have the privilege of dealing with the clone's identity
 * @param {string[]} nMut - array of mutation names
 * @return {Clone|null}
 * @throws {SQLException}
 */
export function Clone_getInstance(size, sampleName, which, nMut) {
    if (which.name() === Perspectives.Identity) {
        return new Identity(size, sampleName, nMut);

    } else if (which.name() === Perspectives.GenomePerspective) {
        return new GenomePerspective(size, sampleName, nMut);

    } else if (which.name() === Perspectives.TranscriptomePerspective) {
        return new TranscriptomePerspective(size, sampleName, nMut);

    } else if (which.name() === Perspectives.KaryotypePerspective) {
        return new KaryotypePerspective(size, sampleName, nMut);

    } else if (which.name() === Perspectives.ExomePerspective) {
        return new ExomePerspective(size, sampleName, nMut);

    } else if (which.name() === Perspectives.MorphologyPerspective) {
        return new MorphologyPerspective(size, sampleName, nMut);

    }

    return null;
}






export function _Clone_getInstance(size, sampleName, which, nMut) {
    const Perspectives = {
        ExomePerspective: "ExomePerspective",
        GenomePerspective: "GenomePerspective",
        TranscriptomePerspective: "TranscriptomePerspective",
        KaryotypePerspective: "KaryotypePerspective",
        MorphologyPerspective: "MorphologyPerspective",
        Identity: "Identity",
        None: "None"
    };
    if (which === Perspectives["Identity"]) {
        return new Identity(size, sampleName, nMut);
    } else if (which === Perspectives["GenomePerspective"]) {
        return new GenomePerspective(size, sampleName, nMut);
    } else if (which === Perspectives["TranscriptomePerspective"]) {
        return new TranscriptomePerspective(size, sampleName, nMut);
    } else if (which === Perspectives["KaryotypePerspective"]) {
        return new KaryotypePerspective(size, sampleName, nMut);
    } else if (which === Perspectives["ExomePerspective"]) {
        return new ExomePerspective(size, sampleName, nMut);
    } else if (which === Perspectives["MorphologyPerspective"]) {
        return new MorphologyPerspective(size, sampleName, nMut);
    }


    return null;
}