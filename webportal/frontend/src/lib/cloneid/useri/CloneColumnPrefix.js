
import { Perspectives } from '../core/utils/Perspectives';
import { Helper } from '../core/utils/Helper';

/**
 * Prefix of columns within an *sps.cbs files, that represent individual clones.
 */
export class CloneColumnPrefix {
    /**
     * @param {Perspectives} which
     */
    static getValue(which) {
        const index = Helper.firstIndexOf(which.name(), CloneColumnPrefix.KEYS);
        return CloneColumnPrefix.VALUES[index];
    }

    static values() {
        const uniqueValues = new Set(CloneColumnPrefix.VALUES);
        return Array.from(uniqueValues);
    }

    static VALUES = ["SP", "SP", "SP", "Clone","SP","Clone"];
    static KEYS = [
        Perspectives.ExomePerspective,
        Perspectives.GenomePerspective,
        Perspectives.KaryotypePerspective,
        Perspectives.TranscriptomePerspective,
        Perspectives.MorphologyPerspective,
        Perspectives.Identity
      ];
}
