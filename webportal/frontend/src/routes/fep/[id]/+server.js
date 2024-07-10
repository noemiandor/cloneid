import { FIDINFO_DIR } from '$env/static/private';
import { promises as fs } from 'fs';
import path from 'path';
/** @type {import('./$types').RequestHandler} */
export async function GET({ params }) {
  const id = params.id;
  try {
    const jsonRealFile = (await fs.readFile(path.resolve(FIDINFO_DIR, `${id}.json`))).toString();
    const realFile = JSON.parse(jsonRealFile);
    const filePath = path.resolve(realFile.file);
    const data = await fs.readFile(filePath);
    const myBlob = new Blob([data]);
    const headers = { 'Content-Type': 'application/zip', 'Content-Disposition': 'inline; filename="' + realFile.name + '"' };
    const myOptions = { status: 200, statusText: "ok", headers: headers };
    const myResponse = new Response(myBlob, myOptions);
    return myResponse;
  } catch (error) {
    return {
      status: 404,
      body: 'File not found',
    };
  }
}