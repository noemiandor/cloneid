import { CELLPOS_DIR, SQLPORT, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { runningInDocker } from "@/lib/mysql/runningInDocker";
import fs from "node:fs";
import path from 'path';
import { normalisePathFromComponents } from './misc';

export async function import2cloneid(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (
        !(
            d.timestamp &&
            d.userhash &&
            d.imageid &&
            d.from &&
            d.media &&
            d.flask &&
            d.cellcount &&
            d.event &&
            d.dishsurfacearea &&
            d.flaskitems &&
            d.mediaitems &&
            d.waitforresult &&
            true
        )
    ){
        console.log(
            d
        )
        return fail(400, { missing: true });
    }

    await new Promise((r) => setTimeout(r, 10000));
    console.log("spawn done");
    return {
        state: 'newlyProcessed',
        action: 'import2cloneid',
        data: JSON.stringify([0])
    };
}
