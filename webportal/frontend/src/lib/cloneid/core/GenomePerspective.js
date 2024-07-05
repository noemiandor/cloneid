import {Genome} from './utils/Genome';
import {Perspectives} from './utils/Perspectives';
import {Perspective} from './Perspective';

export class GenomePerspective extends Perspective {

    /**
     * @param {number} f
     * @param {string} sampleName
     * @param {string[]} nMut
     */
    constructor(f, sampleName, nMut) 
     {
        super(f, sampleName);
        this.profile = new Genome(nMut);
    }

    /**
     * @param {Perspectives} whichP
     */
    getPerspective(whichP) {
        if (whichP.equals(Perspectives.valueOf(this.constructor.name))) {
            return this;
        }
        return null;
    }
}
