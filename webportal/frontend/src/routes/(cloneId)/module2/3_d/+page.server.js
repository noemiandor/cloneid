
import { calculateresults } from "./server/calculateresults.js";
import { commitpassaging } from "./server/commitpassaging.js";
import { getphenoarray } from "./server/getphenoarray.js";
import { import2cloneid } from './server/import2cloneid.js';
import { processgenotype } from "./server/processgenotype.js";
import { processphenotype } from './server/processphenotype.js';
import { processphenotypenotification } from './server/processphenotypenotification.js';
import { processphenotyperesults } from "./server/processphenotyperesults.js";
import { pageServerSaveImgInfo, pageServerSaveSeginfo } from "./server/saveseginfo.js";
import { uploadallphenotypeimages } from "./server/uploadallphenotypeimages.js";
import { uploadgenotype } from "./server/uploadgenotype.js";


/** @type {import('./$types').Actions} */
export const actions = {

  import2cloneid:
    async ({ request }) => { return import2cloneid(request); },

  calculateresults:
    async ({ request }) => { return calculateresults(request); },

  commitpassaging:
    async ({ request }) => { return commitpassaging(request); },

  uploadallphenotypeimages:
    async ({ request }) => { return uploadallphenotypeimages(request); },

  processphenotype:
    async ({ request }) => { return processphenotype(request); },

  processphenotyperesults:
    async ({ request }) => { return processphenotyperesults(request); },

  processphenotypenotification:
    async ({ request }) => { return processphenotypenotification(request); },

  getphenoarray:
    async ({ request }) => { return getphenoarray(request); },

  uploadgenotype:
    async ({ request }) => { return uploadgenotype(request); },

  processgenotype:
    async ({ request }) => { return processgenotype(request); },

  saveseginfo:
    async ({ request }) => { return pageServerSaveSeginfo(request); },

  saveimginfo:
    async ({ request }) => { return pageServerSaveImgInfo(request); },

};
