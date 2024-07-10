import { dev } from "$app/environment";
import { SPSTATS_DIR } from '$env/static/private';
import { projectRoot } from "$lib/util.server";
import { fail } from "@sveltejs/kit";
import fs from "node:fs";
import { mkdir } from 'node:fs/promises';

/**
 * @param {Request} request
 */
export async function uploadgenotype(request)
{
  const formdata = await request.formData();
  const file = formdata.get("file");
  const index = formdata.get("index");
  const destination = SPSTATS_DIR;
  const timeStamp = formdata.get("timestamp");
  const userHash = formdata.get("userhash");

  if (!(file instanceof Object) || !file.name || !userHash) {
    return fail(400, { missing: true });
  }
  const buffer = Buffer.from(await file.arrayBuffer());
  let dirpath;
  if (destination?.toString().startsWith("/")) {
    dirpath = `${destination}/${userHash}/${timeStamp}/`;
  } else {
    dirpath = `/files/${destination}/${userHash}/${timeStamp}/`;
    if (dev) {
      dirpath = `static${dirpath}`;
    } else {
      dirpath = projectRoot + `/public${dirpath}`;
    }
  }

  try {
    await mkdir(dirpath, { recursive: true })
      ;
  } catch (err) {
    console.error(err);
    return fail(400, { mkdir: dirpath, missing: true });
  }


  const filepath = dirpath + file.name;
  fs.writeFileSync(filepath, buffer, "base64");
  return { index: index, timestamp: timeStamp, dirpath: dirpath, filename: file.name };
}
