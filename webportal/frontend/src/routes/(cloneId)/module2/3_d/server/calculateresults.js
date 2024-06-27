import { CELLPOS_DIR } from '$env/static/private';
import { fetchStmtRows } from '@/lib/mysql/fetchFromProxy.js';
import moment from 'moment';
import fs, { readFileSync } from "node:fs";
import { median, normalisePathFromComponents } from './misc.js';
/**
 * @param {Request} request
 */
export async function calculateresults(request) {

    const formdata = await request.formData();

    let d = {};
    for (const [k, v] of formdata) {
      d[k] = v;
    }


    const img_overlay_json = formdata.get("d")?.toString();
    const img_overlay = await JSON.parse(img_overlay_json);

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

    let notif = '';
    if (fs.existsSync(messgefile)) {
      const nb = readFileSync(messgefile);
      if (nb) {
        notif = nb.toString();
      }
    }

    /**
     * @param {Number} accumulator
     * @param {Number} a
     */
    function add(accumulator, a) {
      return accumulator + a;
    }
    const imagecount = img_overlay
      .map((x) => {                   
        return x.checked ? 1 : 0;
      })
      .reduce(add, 0);

    const dishSurfaceArea_cm2 = d.dishsurfacearea;

    if (!dishSurfaceArea_cm2) {
      return ({ data: [] });
    }

    const area_cm2_array = img_overlay.map((x) => {
      return x.checked ? x.area_cm2 : NaN;
    }).filter(x => !isNaN(x));
    const area_cm2 = area_cm2_array.reduce((/** @type {Number} */ accumulator, /** @type {Number} */ currentValue) => {
      return accumulator + currentValue
    }, 0);

    const areaCount_array = img_overlay.map((x) => {
      return x.checked ? x.areacount : NaN;
    }).filter(x => !isNaN(x));
    const areaCount = areaCount_array.reduce((/** @type {Number} */ accumulator, /** @type {Number} */ currentValue) => {
      return accumulator + currentValue
    }, 0);

    const dishAreaOccupied_array = img_overlay.map((/** @type {{ checked: Boolean; dishAreaOccupied: Number; }} */ x) => {
      return x.checked ? x.dishAreaOccupied : NaN;
    }).filter(x => !isNaN(x));
    const dishAreaOccupied = dishAreaOccupied_array.reduce((/** @type {Number} */ accumulator, /** @type {Number} */ currentValue) => {
      return accumulator + currentValue
    }, 0);

    const cellSize_um2_array = img_overlay.map((x) => {
      return x.checked ? x.cellSize_um2 : NaN;
    }).filter(x => !isNaN(x));
    const cellSize_um2 = median(cellSize_um2_array);

    var area2dish = dishSurfaceArea_cm2 / area_cm2;
    var dishCount = Math.round(areaCount * area2dish);
    var dishConfluency = Math.round(dishAreaOccupied * area2dish);
    var cellSize = Math.round(cellSize_um2);

    let data = [
      { k: "images", v: imagecount },
      { k: "cellcount", v: dishCount },
      { k: 'areaOccupied_um2', v: dishConfluency },
      { k: 'cellSize_um2', v: cellSize },
    ];

    return { data: JSON.stringify(data), notif: notif };
  }
