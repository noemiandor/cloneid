
import { processphenotyperesults } from "./processphenotyperesults" 


/** @type {import('./$types').Actions} */
export const actions = {

  processphenotyperesults:
    async ({ request }) => { return processphenotyperesults(request); },

};
