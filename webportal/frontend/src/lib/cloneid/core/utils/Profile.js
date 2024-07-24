export class Profile {

    /**
     * @param {string | any[]} loci
     */
    constructor(loci) {
        this.values = new Array(loci.length);
        this.loci = loci;
    }

    modify(rowI, val) {
        this.values[rowI] = val;
    }

    getValues() {
        return this.values;
    }

    simpleValues() {
        return this.values;
    }

    size() {
        return this.values.length;
    }

    getLoci() {
        return this.loci;
    }

    getLocus(i) {
        return this.loci[i];
    }
}
