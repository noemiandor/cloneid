import { CELLPOS_DIR, FIDINFO_DIR } from '$env/static/private';
import { parse } from 'csv-parse';
import { sha512 } from "js-sha512";
import fs from "node:fs";
import { mkdir } from 'node:fs/promises';
import sharp from "sharp";
import { zip } from 'zip-a-folder';

/**
 * @param {{ formData: () => any; }} request
 * @param {String[]} mandatory
 */
export async function datafromrequest(request, mandatory) {
  let d = {};
  for (const [k, v] of await request.formData()) {
    d[k] = v;
  }
  /**
   * @type {String[]}
   */
  let missingKeys = [];
  const keys = Object.keys(d);
  mandatory.forEach((x) => {
    if (!keys.includes(x)) {
      missingKeys.push(x);
    }
  });
  if (missingKeys.length) {
    return { kv: d, missing: missingKeys };
  }
  return { kv: d };
}

/**
* @private
* @param {Number} a
* @param {Number} b
* @returns {Number}
*/
function ascending(a, b) {
  return a - b;
} 

function quantileX(arr, p) {
  const sortedArr = arr.slice().sort((a, b) => a - b);
  const index = (sortedArr.length - 1) * p;
  const lowerIndex = Math.floor(index);
  const upperIndex = Math.ceil(index);
  const weight = index - lowerIndex;
  if (weight === 0) {
    return sortedArr[index];
  } else {
    return sortedArr[lowerIndex] * (1 - weight) + sortedArr[upperIndex] * weight;
  }
}
/**
 * @param {fs.PathLike} dirpath
 */
export function listDir(dirpath) {
  if (!fs.existsSync(dirpath)) return [];
  return fs.readdirSync(dirpath, {
    withFileTypes: true,
    recursive: true
  });
}

/**
 * @param {string} srcimages
 */
export async function listDirWithImgSrc(srcimages, transform = true, kv = true) {
  let ls2 = [];
  let ls3 = {};
  const ls = listDir(srcimages).filter((x) => (!x.name.startsWith("."))).filter((x) => (x.name.endsWith(".png")));
  for (const x of ls) {
    const f = normalisePathFromComponents([x.path, x.name]);
    const imgdata = await resizeImage(f, 640, 480);
    const imgsrc = "data:image/jpeg;base64," + imgdata.toString('base64');
    const fb = "data:image/png;base64," + fs.readFileSync(f, 'base64');
    const imgprefix = (x.name).replace(/_overlay.png/i, '');
    let imgsuffix = '';
    const imgsuffixmatch = /_10x_ph_(.+)$/.exec(imgprefix);
    if (imgsuffixmatch) {
      imgsuffix = imgsuffixmatch[1];
    }

    if (imgdata) {
      const record = ({
        prefix: imgprefix,
        suffix: imgsuffix,
        name: x.name,
        path: x.path,
        imgsrc: (transform ? imgsrc : fb),
        srclen: imgsrc.length,
      });
      ls2.push(record);
      ls3[imgprefix] = record;
    }
  };
  return kv ? ls3 : ls2;
}


/**
 * @param {string[]} a
 */
export function normalisePathFromComponents(a, retainFirstSlash = true) {
  let slash = '';
  if (retainFirstSlash) {
    if (a[0].startsWith('/')) {
      slash = '/';
    }
  }
  return slash + a.map((p) => {
    if (!p) return '';
    if (p === '') return '';
    let q = p.trim();
    q = q.replace(/^\/+|\/+$/g, '');
    return q;
  }).join('/');
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
    fs.writeFileSync(normalisePathFromComponents([d.p, f.name]), b);
    fs.writeFileSync(normalisePathFromComponents([d.i, f.name]), b);
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
        c++;
      } else {
        console.log("ERR", v.name);
      }
    }
  }
  return { c: c };
}

export function median(arr) {
  if (arr.length == 0) {
    return 0;
  }
  arr.sort((a, b) => a - b); // 1.
  const midpoint = Math.floor(arr.length / 2); // 2.
  const median = arr.length % 2 === 1 ? arr[midpoint] : (arr[midpoint - 1] + arr[midpoint]) / 2;
  return median;
}


/**
 * @param {string} f
 */
export async function resizeImage(f, width = 320, height = 240) {
  const data = await sharp(f)
    .resize(width, height, {
      fit: sharp.fit.inside,
      withoutEnlargement: true
    })
    .toFormat('jpeg')
    .toBuffer()
    .then((data) => {
      return data;
    })
    .catch((e) => {
      console.error('CATCH sharp: ', e, f);
    });
  return data;
}



export async function calculateresult1(d) {

  let srcpath = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', d.s]);
  let dstpath = normalisePathFromComponents([CELLPOS_DIR, d.h, d.t]);
  const log = normalisePathFromComponents([srcpath, 'processed.log']);
  const alreadyProcessed = fs.existsSync(log);
  const srcoutput = normalisePathFromComponents([srcpath, 'output']);
  const dstoutput = normalisePathFromComponents([dstpath, 'output']);
  const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
  const stdoutfile = normalisePathFromComponents([srcpath, 'stdout.txt']);
  const stderrfile = normalisePathFromComponents([srcpath, 'stderr.txt']);
  const notififile = normalisePathFromComponents([srcpath, 'notification.txt']);
  const messgefile = normalisePathFromComponents([srcpath, 'messages.txt']);


  let celldata = [];
  let celldatakv = {};

  const dishSurfaceArea_cm2 = d.dishsurfacearea;

  if (!dishSurfaceArea_cm2) {
    return ({ data: [] });
  }

  const annotationdir = normalisePathFromComponents([srcoutput, 'Annotations']);
  const annotationfilelist = listDir(annotationdir).filter((x) => (x.name.endsWith(".csv")));
  for (const x of annotationfilelist) {
    const f = normalisePathFromComponents([x.path, x.name]);
    const content = fs.readFileSync(f);
    let celldatarecord = {};
    celldatarecord.imgname = (x.name).replace(/\.csv/i, '');
    const imgsuffixmatch = /_10x_ph_(.+)$/.exec(celldatarecord.imgname);
    if (imgsuffixmatch) {
      celldatarecord.imgsuffix = imgsuffixmatch[1];
    }
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      delimiter: [',', '\t'],
      trim: true,
    });
    if (records) {
      for await (const y of records) {
        celldatarecord.areacount = Number(y['Num Detections']);
        celldatarecord.area_cm2 = Number(y['Area µm^2']) / 100000000.0;
      }
    }
    celldata.push(celldatarecord);
    celldatakv[celldatarecord.imgname] = celldatarecord;
  };

  const confluencydir = normalisePathFromComponents([srcoutput, 'Confluency']);
  const confluencyfilelist = listDir(confluencydir).filter((x) => (x.name.endsWith(".csv")));
  for (const x of confluencyfilelist) {
    const f = normalisePathFromComponents([x.path, x.name]);
    const content = fs.readFileSync(f);
    let celldatarecord = {};
    celldatarecord.imgname = (x.name).replace(/\.csv/i, '');
    const imgsuffixmatch = /_10x_ph_(.+)$/.exec(celldatarecord.imgname);
    if (imgsuffixmatch) {
      celldatarecord.imgsuffix = imgsuffixmatch[1];
    }
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      delimiter: [',', '\t'],
      trim: true,
    });
    let dishAreaOccupied = 0;
    if (records) {
      const key = 'Area in um';
      for await (const y of records) {
        dishAreaOccupied += Number(y[key]);
      }
    }
    celldatakv[celldatarecord.imgname]['dishAreaOccupied'] = dishAreaOccupied;
  };

  const detectionrdir = normalisePathFromComponents([srcoutput, 'DetectionResults']);
  const detectionrfilelist = listDir(detectionrdir).filter((x) => (x.name.endsWith(".csv")));
  for (const x of detectionrfilelist) {
    const f = normalisePathFromComponents([x.path, x.name]);
    const content = fs.readFileSync(f);
    let celldatarecord = {};
    celldatarecord.imgname = (x.name).replace(/\.csv/i, '');
    const imgsuffixmatch = /_10x_ph_(.+)$/.exec(celldatarecord.imgname);
    if (imgsuffixmatch) {
      celldatarecord.imgsuffix = imgsuffixmatch[1];
    }
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      delimiter: [',', '\t'],
      trim: true,
    });
    let cellSize_um2 = [];
    if (records) {
      const key = 'Area µm^2';
      for await (const y of records) {
        const v = Number(y[key]);
        if (v) cellSize_um2.push(Number(y[key]));
      }
    }

    const sorted_cellSize_um2 = cellSize_um2.sort((a, b) => a - b);
    const qcellSize_um2_2 = quantileX(sorted_cellSize_um2, 0.9)
    celldatakv[celldatarecord.imgname]['cellSize_um2'] = qcellSize_um2_2;
  };

  celldata = Object.values(celldatakv).map((x) => {
    return x;
  });

  return celldatakv;
}


/**
 * @param {{ imageid: string; s: string; }} d
 * @param {string} srczip
 * @param {string} dstpath
 */
export async function createZipResults(d, srczip, dstpath) {
  const zipoutput = normalisePathFromComponents([dstpath, 'output.zip']);
  const fid = ({
    "file": zipoutput,
    "name": d.imageid + ".zip",
    "type": "download",
  });
  const fidoutput = normalisePathFromComponents([FIDINFO_DIR, `${d.s}.json`]);
  fs.writeFileSync(fidoutput, JSON.stringify(fid));
  await zip(srczip, zipoutput);
}



/**
 * @param {Response} res
 */
export async function setImageArrays(res) {
  const x = await res.json();
  let d = {};
  if (
    x.status === 200
  ) {
    d = decoderesponse(x);
    const ls = await JSON.parse(d.ls);
    d.ls = ls;
    phenotypeImgOverlay = ls.map((x) => {
      x.reload = 0;
      x.checked = true;
      x.imgname = x.name;
      return x;
    });
    phenotypeImgOverlayData = ls.map((x) => {
      x.reload = 0;
      x.checked = true;
      x.imgname = x.name;
      return x;
    });
    await mi_notif('FDONE2000');
    cellpose_processing = false;
  } else {
    cellpose_processing = false;
    console.log('X', x);
    await mi_notif('EPROCESSING3000');
  }
}