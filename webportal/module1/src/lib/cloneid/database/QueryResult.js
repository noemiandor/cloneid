export class QueryResult {

    constructor(data) {
        this.init(data)
    }

    /**
     * @param {{ [x: string]: string[]; }} data
     */
    init(data){
        this.rows = (data && 'rows' in data) ? data['rows'] : [];
        this.entries = this.rows.length;
        this.fields = (data && 'fields' in data) ? data['fields'] : [];
        this.index = 0;
        this.row = (this.entries > 0) ? this.rows[this.index] : [];
        this.setIndexed = [];
        this.index = -1;
    }

    index = 0;
    entries = 0;
    /**
     * @type {string[]}
     */
    fields = [];
    /**
     * @type {{}[]}
     */
    #rows = [];
    row = {}
    next() {
        if (this.index < this.entries - 1) {
            this.index++;
            this.row = this.rows[this.index];
            this.setIndexed = [];
            return this.index;
        } else {
            return null;
        }
    }
    previous() {
        if (this.index > 0) {
            this.index--;
            this.row = this.rows[this.index];
            this.setIndexed = [];
            return this.index;
        } else {
            return null;
        }
    }
    set setIndexed(x) {
        let index = 0;
        /**
         * @type {[string, any][]}
         */
        let arr = [];
        Object.entries(this.row).forEach((o) => {
            arr[index++] = o[1];
        });
        this.indexed = arr;
    }
    get getIndexed() {
        return this.indexed;
    }
    value(index){
        return (typeof index == 'string') ?
        (index in this.row ? this.row[index] : null) :
        ((index > 0) ? this.indexed[index - 1] : null)
    }
    /**
     * @param {string | number} index
     */
    getInt(index) {
        return parseInt(this.value(index));
    }
    /**
     * @param {string | number} index
     */
    getFloat(index) {
        return parseFloat(this.value(index))
    }
    /**
     * @param {number} index
     */
    getString(index) {
        return `${this.value(index)}`
    }
    /**
     * @param {number} index
     */
    getBytes(index) {
        const buffer = new Uint8Array(this.value(index));
        return buffer;
    }
    close(){}
}