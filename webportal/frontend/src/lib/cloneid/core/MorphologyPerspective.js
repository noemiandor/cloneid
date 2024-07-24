import { Perspective } from "./Perspective";
import { Genome } from "./utils/Genome";
import { Perspectives } from "./utils/Perspectives";

export class MorphologyPerspective extends Perspective {
  /**
     * @param {number} f
     * @param {string} sampleName
     * @param {string[]} nMut
     */
  constructor(f, sampleName, nMut) {
    super(f, sampleName);
    this.profile = new Genome(nMut);
  }

  /**
     * @param {Perspectives} whichP
     */
  getPerspective(whichP) {
    if (whichP == Perspectives.valueOf(this.constructor.name)) {
        return this;
    }
    return null;
  }
}
