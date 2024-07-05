export class Perspectives {
    /**
     * @param {string} name
     */
    constructor(name) {
        if (name in Perspectives.shortKeys) {
            this._name = Perspectives.shortKeys[name];
        }
        if (name in Perspectives.longKeys) {
            this._name = Perspectives.longKeys[name];
        }
        this.ExomePerspective = "";
        this.GenomePerspective = "";
        this.TranscriptomePerspective = "";
        this.KaryotypePerspective = "";
        this.MorphologyPerspective = "";
        this.Identity = "";

        const nametlc = name.toLowerCase();
        if (nametlc.startsWith("exome")
        ) {
            this.setExomePerspective = "ExomePerspective";
        }
        if (nametlc.startsWith("genome")
        ) {
            this.setGenomePerspective = "GenomePerspective";
        }
        if (nametlc.startsWith("transcriptome")
        ) {
            this.setTranscriptomePerspective = "TranscriptomePerspective";
        }
        if (nametlc.startsWith("karyotype")
        ) {
            this.setKaryotypePerspective = "KaryotypePerspective";
        }
        if (nametlc.startsWith("morphology")
        ) {
            this.setMorphologyPerspective = "MorphologyPerspective";
        }
        if (nametlc.startsWith("identity") || nametlc.startsWith("exome")
        ) {
            this.setIdentity = "Identity";
        }
    }

    static ExomePerspective = "ExomePerspective";
    static GenomePerspective = "GenomePerspective";
    static TranscriptomePerspective = "TranscriptomePerspective";
    static KaryotypePerspective = "KaryotypePerspective";
    static MorphologyPerspective = "MorphologyPerspective";
    static Identity = "Identity";

    static longKeys = {
        "ExomePerspective": "ExomePerspective",
        "GenomePerspective": "GenomePerspective",
        "TranscriptomePerspective": "TranscriptomePerspective",
        "KaryotypePerspective": "KaryotypePerspective",
        "MorphologyPerspective": "MorphologyPerspective",
        "Identity": "Identity",
        "exomeperspective": "ExomePerspective",
        "genomeperspective": "GenomePerspective",
        "transcriptomeperspective": "TranscriptomePerspective",
        "karyotypeperspective": "KaryotypePerspective",
        "morphologyperspective": "MorphologyPerspective",
        "identity": "Identity"
    };

    static shortKeys = {
        "Exome": "ExomePerspective",
        "Genome": "GenomePerspective",
        "Transcriptome": "TranscriptomePerspective",
        "Karyotype": "KaryotypePerspective",
        "Morphology": "MorphologyPerspective",
        "Identity": "Identity"
    }
    _name = '';
    name() {
        return this._name;
    }

    includes(x) {
        return this._name.includes(x);
    }

    ExomePerspective = "";
    GenomePerspective = "";
    TranscriptomePerspective = "";
    KaryotypePerspective = "";
    MorphologyPerspective = "";
    Identity = "";

    set setExomePerspective(x) {
        this.ExomePerspective = x;
    }
    get getExomePerspective() {
        return this.ExomePerspective;
    }

    set setGenomePerspective(x) {
        this.GenomePerspective = x;
    }
    get getGenomePerspective() {
        return this.GenomePerspective;
    }

    set setTranscriptomePerspective(x) {
        this.TranscriptomePerspective = x;
    }
    get getTranscriptomePerspective() {
        return this.TranscriptomePerspective;
    }

    set setKaryotypePerspective(x) {
        this.KaryotypePerspective = x;
    }
    get getKaryotypePerspective() {
        return this.KaryotypePerspective;
    }

    set setMorphologyPerspective(x) {
        this.MorphologyPerspective = x;
    }
    get getMorphologyPerspective() {
        return this.MorphologyPerspective;
    }

    set setIdentity(x) {
        this.Identity = x;
    }
    get getIdentity() {
        return this.Identity;
    }

}
;