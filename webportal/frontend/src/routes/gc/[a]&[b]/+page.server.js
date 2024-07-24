import { FIDINFO_DIR } from '$env/static/private';
import { fail } from "@sveltejs/kit";
import fs from "node:fs";
import path from "node:path";

/**
 * @param {Request} request
 */
async function gc(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (!(d.k && d.k)) {
        return fail(400, { missing: true });
    }

    const jsonPath = path.resolve(FIDINFO_DIR, `${d.k}.json`);
    const fContent = fs.readFileSync(jsonPath).toString();
    const jsonData = JSON.parse(fContent);

    const r = ({ d: JSON.stringify(jsonData) });
    return r;
}

/** @type {import('./$types').Actions} */
export const actions = {
    gc:
        async ({ request }) => {
            return gc(request);
        },
}