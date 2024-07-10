import { JOBINFO_DIR } from '$env/static/private';
import pkg from 'fs-extra';
import { sha512 } from "js-sha512";
import fs, { existsSync, readFileSync, writeFileSync } from "node:fs";
import { mkdir } from 'node:fs/promises';
import { createGcPayload } from '../gc/createGcPayload';
import { logmessage } from "../log";
import { normalisePathFromComponents } from "./path.js";
import { getPushedEvents, ping, readAndArchive, readAndKeep, readAndMoveToPulled } from './readAndArchive';
const { removeSync } = pkg;

export async function createJbPayload(a, q, i, p) {
  if (!(a && q && p)) {
    throw "createJbPayload";
  }
  console.log("createJbPayload", "A", a, "Q", q, "I", i, "P", p)
  const ts = i ? i : (new Date()).getTime();
  const j = ({
    a: a,
    q: q,
    i: ts,
    c: await createGcPayload(ts, a, p),
    p: JSON.parse(p),
    // p: p
  });
  const jf = normalisePathFromComponents([JOBINFO_DIR, a, q, `${ts}.json`]);
  writeFileSync(jf, JSON.stringify(j));
  return j;
}

export async function serverCreateJbPayload(a, q, i, p) {
  if (!(a && q && p)) {
    throw "createJbPayload";
  }
  var sqluser = process.env.SQLUSER;
  const ts = i ? i : (new Date()).getTime();
  const j = ({
    a: a,
    q: q,
    i: ts,
    c: await createGcPayload(ts, a, p),
    p: p,
    sqluser: sqluser,
  });
  const jf = normalisePathFromComponents([JOBINFO_DIR, a, q, `${ts}.json`]);
  writeFileSync(jf, JSON.stringify(j));
  return j;
}

/**
 * @param {string} i
 * @param {string} t
 * @param {string} q
 * @param {any} p
 */
export async function extractJobPayload(a, q, i) {
  if (!(i && q)) {
    throw "extractJobPayload";
  }
  // const jts = i;
  const jf = normalisePathFromComponents([JOBINFO_DIR, a, q, `${i}.json`]);
  const b = readFileSync(jf);
  const p = JSON.parse(b.toString());
  console.log("extractJobPayload J", p);
  return p;
}

/**
 * @param {string} id
 * @param {string} t
 * @param {string} s
 * @param {any} p
 */
export async function findAndExtractMultipleJbPayload(app, queue, id) {
  if (!(id)) {
    throw "findAndExtractMultipleJbPayload";
  }
  const states = ['waiting', 'pending', 'done', 'error'];

  let jid = {};
  jid.state = 'none';

  for (const state of states) {
    const jidf = normalisePathFromComponents([JOBINFO_DIR, app, state, `${id}.json`]);
    if (existsSync(jidf)) {
      const data = readFileSync(jidf);
      jid = JSON.parse(data.toString());
      jid.q = state;
      const events = [];

      const pulled = getPushedEvents(app, id);


      for (const f of pulled) {
        const s = readAndMoveToPulled(app, id, f);
        const parts = f.split('_');
        const eventparts = parts[1].split('.');
        const event = eventparts[0].toUpperCase();
        events.push({ k: event, v: s });
      }
      jid.PUSHED = events;
      jid.state = state;
      break;
    }
  }
  if (jid.state === 'none') {
    jid.killed = true;
    console.log("findAndExtractMultipleJbPayload NOSHOW", jid.state, id);
  }
  if (ping(app, id) < 0) {
    if (!['waiting', 'pending', 'done', 'error'].includes(jid.state)) {
      console.log("findAndExtractMultipleJbPayload NOSHOW", jid.state, id);
      jid.noshow = true;
    }
  }
  return jid;
  return null;
}

/**
 * @param {string} id
 * @param {string} t
 * @param {string} s
 * @param {any} p
 */
export async function findAndExtractJbPayload(app, queue, id) {
  if (!(id)) {
    throw "extractJbPayload";
  }
  const states = ['waiting', 'pending', 'done', 'error'];
  const artefacts = ['spawn'];
  for (let sx in states) {
    const state = states[sx];
    const jidf = normalisePathFromComponents([JOBINFO_DIR, app, state, `${id}.json`]);
    if (existsSync(jidf)) {
      const data = readFileSync(jidf);
      const example = {
        a: "m2.cellpose",
        q: "waiting",
        i: 1709263961170,
        c: "26b13d2fa2e9d491eadac9ca05ee998338bbbab8c727567bf0146358b8ab0af4ad9e0f5ce8c365e9d8b46949b255bf53a2e399d0cd3bc4e51f4fea4b3002b8e8",
        p: {
          spawn: ["Rscript", "--vanilla", "/opt/lake/data/cloneid/module02/data/scripts/manageInput1.R"]
        }
      }
      const jid = JSON.parse(data.toString());
      jid.q = state;
      let errdata;
      let outdata;
      let aiqdata;


      /**
       * @type {string[]}
       */
      const events = [];


      [
        'ABRT',
        'DONE',
        'INFO',
        'JSON',
        'MESG',
        'MSQL',
        'NTIF',
        'PRNT',
        'QUIT',
        'RSLT',
        'VARS',
        'WRNG',
      ].forEach((header) => {
        const s = readAndArchive(app, id, header.toLocaleLowerCase() + '.txt');
        if (s) {
          events.push(header);
          jid[header] = s;
        }
      });

      [
        'AFIQ',
        'AFIR',
      ].forEach((header) => {
        const s = readAndKeep(app, id, header.toLocaleLowerCase() + '.txt');
        if (s) {
          events.push(header);
          jid[header] = s;
        }
      });

      jid.EVENTS = events;
      return jid;
    }
  }
  // console.log("extractJbPayload xx", xx);
  return null;

}
/**
* @param {string} id
* @param {string} t
* @param {string} s
* @param {any} p
*/

export async function extractJbPayload(dir, app, queue, id) {
  if (!(id && dir)) {
    throw "extractJbPayload";
  }
  const states = ['waiting', 'pending', 'done', 'error'];
  const artefacts = ['spawn'];
  for (let sx in states) {
    const state = states[sx];
    const jidf = normalisePathFromComponents([dir, app, state, `${id}.json`]);
    logmessage([jidf]);
    if (existsSync(jidf)) {
      const data = readFileSync(jidf);
      const jid = JSON.parse(data.toString());
      jid.q = state;
      return jid;
    }
  }
  return null;

}



export async function afianswer(p) {
  if (!(p.i || p.txid)) {
    throw "afianswer";
  }
  const id = p.i ? p.i : (p.txid ? p.txid : '');
  const jf = normalisePathFromComponents([JOBINFO_DIR, 'm2.cellpose', 'spawn', id, 'afinputa.txt']);
  writeFileSync(jf, Buffer.from(`${p.selected}\n`));
}




/**
 * @param {File} f
 */
async function filesha(f) {
  return sha512(Buffer.from(await f.arrayBuffer()));
}
/**
 * @param { File[] } f
 */
export async function filessha(f) {
  let s = "";

  for (const x of f.filter((x) => (x))) {
    s += await filesha(x)
  };
  return sha512(s).toString();
}
export async function savefileindir(f, d) {
  try {
    await mkdir(d.p, { recursive: true })
    await mkdir(d.i, { recursive: true })
  } catch (e) {
    console.error(e);
    console.log("catch::upload::mkdir", d);
    return false;
  }
  let r = false;
  const b = Buffer.from(await f.arrayBuffer());
  try {
    fs.writeFileSync(d.p + f.name, b);
    fs.writeFileSync(d.i + f.name, b);
    return true;
  } catch (e) {
    return false;
  }
}
export async function savefilesin(d) {
  let c = 0;
  let r = false
  let s = "";
  for (let [k, v] of Object.entries(d)) {
    if (v instanceof File) {
      r = await savefileindir(v, d);
      if (r) {
        // s += r;
        c++;
      } else {
        console.log("ERR", v.name);
      }
    }
  }
  return { c: c };
  // return { c:c, s:sha512(s) };
}
