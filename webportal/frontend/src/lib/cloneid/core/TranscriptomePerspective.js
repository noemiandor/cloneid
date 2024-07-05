import { Perspective } from './Perspective';
import { Perspectives } from './utils/Perspectives';
import { Transcriptome } from './utils/Transcriptome';

export class TranscriptomePerspective extends Perspective {
  constructor(f, sampleName, nMut) {
    super(f, sampleName);
    this.profile = new Transcriptome(nMut);
  }


  getPerspective(whichP) {
    if (whichP === Perspectives[this.constructor.name]) {
      return this;
    }
    return null;
  }
}