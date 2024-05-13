import { Clone } from './Clone';
export class Identity extends Clone {
    constructor(size, sampleName, nMut) {
      super(size, sampleName);
      this.profile = new Profile(nMut);
      this.perspectives = new Map();
    }
  
    save2DB() {
      super.save2DB();
      let db = new CLONEID();
      db.connect();
      for (let ps of this.perspectives.values()) {
        let ids = "";
        let fieldName = null;
        for (let p of ps) {
          ids += p.getID() + ",";
          fieldName = p.constructor.name;
        }
        ids = Helper.replaceLast(ids, ",");
        db.update(this, fieldName, "'" + ids + "'");
      }
      db.close();
    }
  
    getDBformattedAttributesAsMap() {
      let map = super.getDBformattedAttributesAsMap();
      map["whichPerspective"] = "'" + this.constructor.name + "'";
      return map;
    }
  
    addPerspective(clone) {
      let l = new Set();
      let key = Perspectives.valueOf(clone.constructor.name);
      if (this.perspectives.has(key)) {
        l = this.perspectives.get(key);
      }
      l.add(clone);
      this.perspectives.set(key, l);
    }
  
    getPerspective(p) {
      return this.perspectives.get(p).values().next().value;
    }
  
    getPerspectives(p) {
      return this.perspectives.get(p);
    }
  }
  