<<<<<<< HEAD
=======
// import { Inspector, Runtime } from '@observablehq/runtime';
>>>>>>> master
import * as d from 'umap-js';
import * as d3 from 'd3';
import * as os from 'os';
import seedrandom from 'seedrandom';

<<<<<<< HEAD
=======
// export function context2d(width, height, dpi) {
//   if (dpi == null) dpi = devicePixelRatio;
//   var canvas = document.createElement("canvas");
//   canvas.width = width * dpi;
//   canvas.height = height * dpi;
//   canvas.style.width = width + "px";
//   var context = canvas.getContext("2d");
//   context.scale(dpi, dpi);
//   return context;
// }

// import * as transpose_labeled from "./transpose_labeled.js";

//TODO: CHANGE 1000  to something else

>>>>>>> master
function __labels(d3, data) {

  let labels = data.map(d => d.label);
  if (labels.some(d => d)) {
    const labelCount = d3.scaleOrdinal().range(d3.range(data.length));
    return labels.map(d => (d && d !== -1 ? labelCount(d) : -1));
  }
}

function __numericfields(d3, data) {
  return (
    (data.columns || Object.keys(data[0])).filter(
      d =>
        d !== "label" &&
        d !== "title" &&
        d !== "color" &&
        data[0][d] === +data[0][d]
    )
  )
}

function __vectors(d3, data, numericfields) {
  const maxpoints = 10000; //MAXPOINTS;
<<<<<<< HEAD
=======
  console.log("46 DATA", data.length);
  console.log("43 __vect os.freemem", os.freemem());
>>>>>>> master

  const vectors = data.map(d => numericfields.map(f => d[f]));
  const normalize = false;
  if (normalize) {
    for (let i = 0; i < numericfields.length; i++) {
      const mean = d3.mean(data, d => d[i]),
        deviation = d3.deviation(data, d => d[i]),
        scale = d3.scaleSymlog();
      if (deviation > 0)
        for (const d of vectors) d[i] = scale((d[i] - mean) / deviation);
    }
  }
  return vectors.slice(0, maxpoints);
}

<<<<<<< HEAD

function __distances(d3, vectors, distanceType) {
=======
// const __config = {
//   nComponents: 2,
//   minDist: 0.1,
//   nNeighbors: 15,
//   nEpochs: 200,
// };

function __distances(d3, vectors, distanceType) {
  console.log("43 __dist os.freemem", os.freemem());
>>>>>>> master
  const D = {
    one: (a, b) => 1,
    random: (a, b) => Math.random(),
    euclidian: (a, b) =>
      Math.sqrt(a.map((_, i) => (a[i] - b[i]) ** 2).reduce((a, b) => a + b, 0)),
    cosine: (a, b) => {
      const dot = a.map((_, i) => a[i] * b[i]).reduce((a, b) => a + b, 0),
        norm2A = a.map(u => u ** 2).reduce((a, b) => a + b, 0),
        norm2B = norm2A ? b.map(u => u ** 2).reduce((a, b) => a + b, 0) : 0,
        N = norm2A * norm2B;
      return !N ? 1 : Math.acos(dot / Math.sqrt(N)) / Math.PI;
    }
  };

  const distance = D[distanceType] || D["euclidian"];

  const N = vectors.length,
    distances = Float32Array.from({ length: N ** 2 });
  for (let i = 0; i < N; i++) {
    const a = vectors[i];
    distances[i + N * i] = 0;
    for (let j = 0; j < i; j++) {
      const b = vectors[j];
      distances[i + N * j] = distances[j + N * i] = distance(a, b);
    }
  }
  return distances;
}

function __fit(d3, UMAP, distances, labels) {

  const time = performance.now();
<<<<<<< HEAD
=======
  console.log("100 __fit", os.freemem());
>>>>>>> master

  const cfg = {
    nComponents: 2,
    nEpochs: 200,
    nNeighbors: 15,
    minDist: 0.1,
    spread: 1,
    random: (a, b) => Math.random(),
    negativeSampleRate: 5,
    localConnectivity: 1,
    setOpMixRatio: 1,
<<<<<<< HEAD
  };
  const umap = new UMAP(cfg);
  if (labels) umap.setSupervisedProjection(labels);
  const N = Math.sqrt(distances.length);

=======

    // random: ()=>{} 
  };
  // console.log("config433", config);
  // const umap = new UMAP(config);
  const umap = new UMAP(cfg);
  // console.log("LABELS", labels);
  if (labels) umap.setSupervisedProjection(labels);
  // const flat = typeof distances[0] === "number",
  //   N = flat ? Math.sqrt(distances.length) : distances.length;
  const N = Math.sqrt(distances.length);

  //   console.log("FLAT", flat);
  // umap.distanceFn = flat
  // umap.distanceFn = true
  //   ? function (i, j) {
  //     return distances[i + N * j];
  //   }
  //   : function (i, j) {
  //     return distances[i] ? distances[i][j] : 1000;
  //   };
>>>>>>> master
  umap.distanceFn = function (i, j) {
    return distances[i + N * j];
  }

  return {
    result: umap.fit(Uint32Array.from({ length: N }, (_, i) => i)),
    time: performance.now() - time
  };
}

/**
 * @param {typeof import("d3")} d3
 * @param {typeof d.UMAP} UMAP
 * @param {{ getContext: (arg0: string) => any; }} DOM
 * @param {number} width
 * @param {number} height
 * @param {any[]} rawdata
 */
function _chart(d3, UMAP, DOM, width, height, rawdata) {
<<<<<<< HEAD
  let classify = d3.scaleOrdinal(d3.schemeCategory10);

  classify = d3
    .scaleOrdinal()
    .domain(rawdata.map((d) => d.subClone))
    .range(d3.quantize((t) => d3.interpolateSpectral(t * 0.8 + 0.1), rawdata.length).reverse());

=======
  console.log("_chart 153", DOM, width, height);
  console.log("154 _chart", os.freemem());
  // const d3 = await import("https://cdn.skypack.dev/d3@5");
  // const d = await import("https://cdn.skypack.dev/umap-js@1.3.3");
  // const R = await import("https://cdn.skypack.dev/seedrandom");

  let classify = d3.scaleOrdinal(d3.schemeCategory10);

  classify = d3
  .scaleOrdinal()
  .domain(rawdata.map((d) => d.subClone))
  .range(d3.quantize((t) => d3.interpolateSpectral(t * 0.8 + 0.1), rawdata.length).reverse());


  // classify = d3.scaleOrdinal(d3.schemeRdGy);
  // classify = d3.scaleOrdinal(d3.schemeSpectral);
  // classify = d3.scaleOrdinal(d3.schemeRdYlGn);
  // classify = d3.scaleOrdinal(d3.schemeRdYlBu);
  // classify = d3.scaleOrdinal(d3.schemeRdGy);
  // classify = d3.scaleOrdinal(d3.schemeRdBu);
  // classify = d3.scaleOrdinal(d3.schemeTableau10);
  // classify = d3.scaleOrdinal(d3.schemeSet3);
  // classify = d3.scaleOrdinal(d3.schemeSet2);
  // classify = d3.scaleOrdinal(d3.schemeSet1);
  // classify = d3.scaleOrdinal(d3.schemePastel2);
  // classify = d3.scaleOrdinal(d3.schemePastel1);
  // classify = d3.scaleOrdinal(d3.schemePaired);
  // classify = d3.scaleOrdinal(d3.schemeAccent);

  // const rawdata = transpose_labeled.data;
>>>>>>> master
  const data = rawdata.map(d => {
    d.color = classify(d.subClone);
    d.label = d.subProfile;
    return d;
  });
<<<<<<< HEAD
=======
  console.log("175 UMAPSERVER", data.length);
  // $0.value = result;


  // const seedrandom = R.default;
  // seedrandom('hello.', { global: true });
  // console.log("R", Math.random(), Math.random());

  // console.log("D3", d3);
>>>>>>> master

  const labels = __labels(d3, data);
  const numericfields = __numericfields(d3, data);
  const vectors = __vectors(d3, data, numericfields);
  const distances = __distances(d3, vectors, 'euclidean');
<<<<<<< HEAD
=======
  // const dynamic = false;

  // const UMAP = d.UMAP;
>>>>>>> master

  const res = __fit(d3, UMAP, distances, labels)
  const pos = res.result || vectors;

<<<<<<< HEAD
=======
  console.log("LINE196 UMAPJS", pos.length);

  // return pos;

>>>>>>> master
  const columns = data.columns || Object.keys(data[0]);


  var color0 = d3
    .scaleLinear()
<<<<<<< HEAD
    .range(["red", "lime"])
=======
    // .scaleOrdinal()
    // .scaleLog()
    .range(["red", "lime"])
    // .range(["#f00", "#00f"])
    // .range(["white", "black"])
>>>>>>> master
    .domain([0, vectors.length])



  // Create the color scale.
  var color = d3.scaleOrdinal()
<<<<<<< HEAD
    .domain(data.map(d => d.subClone))
    .range(d3.quantize(t => d3.interpolateSpectral(t * 0.8 + 0.1), data.length).reverse())
  return pos.map((d, i) => {
    const row = ({ x: d[0], y: d[1], color: color(i), subclone: data[i].subClone });
    return row;
  });

=======
  .domain(data.map(d => d.subClone))
  .range(d3.quantize(t => d3.interpolateSpectral(t * 0.8 + 0.1), data.length).reverse())


  // const height = width * 0.6;
  // const context = DOM.context2d(width, height);
  // const context0 = DOM.getContext('2d');



  // const N = pos.length,
    // n = Math.sqrt(N),
    // x = d3
    //   .scaleLinear()
    //   .domain(d3.extent(pos.map(d => d[0])))
    //   .range([width / 2 - height * 0.45, width / 2 + height * 0.45]),

    // y = d3
    //   .scaleLinear()
    //   .domain(d3.extent(pos.map(d => d[1] || d[0] || 0)))
    //   .range([height * 0.05, height * 0.95]),

    // z = d3
    //   .scaleLinear()
    //   .domain(d3.extent(pos.map(d => d[2] || 0)))
    //   .range([12 / Math.log(N), 40 / Math.log(N)]); // point size (for cheap-o 3D embeddings)

  // console.log("D3", x, y, z);
  return pos.map((d, i) => {
    // console.log("D3", d, i, z(d[2] || 0), coords(i), (data[i].color || color(i)),);
    // const row = ({ x: d[0], y: d[1], color: data[i].color, subclone:data[i].subClone });
    const row = ({ x: d[0], y: d[1], color: color(i), subclone:data[i].subClone });
    // console.log("D3", row);
    return row;
  });

  if (columns.indexOf("title") > -1) {
    context.fillStyle = "black";
    context.textAlign = "center";
    context.textBaseline = "hanging";
    pos.forEach((d, i) => {
      const c = coords(i);
      context.fillText(data[i]["title"], c[0], c[1] + z(d[2] || 0));
    });
  }
  return pos;
>>>>>>> master

  function coords(i) {
    return [x(pos[i][0] || 0), y(pos[i][1] || pos[i][0] || 0)];
  }

<<<<<<< HEAD
}

export async function _view(DOM, width, height, data) {

  seedrandom("593335098", { global: true });

=======
  const path = d3.geoPath(d3.geoIdentity()).context(context);
  pos.forEach((d, i) => {
    context.beginPath();
    path.pointRadius(z(d[2] || 0));
    path({
      type: "Point",
      coordinates: coords(i)
    });
    context.fillStyle = data[i].color || color(i);
    context.fill();
    context.strokeStyle = labels && labels[i] > -1 ? "black" : "white";
    context.lineWidth = 0.5;
    context.stroke();
  });

  if (columns.indexOf("title") > -1) {
    context.fillStyle = "black";
    context.textAlign = "center";
    context.textBaseline = "hanging";
    pos.forEach((d, i) => {
      const c = coords(i);
      context.fillText(data[i]["title"], c[0], c[1] + z(d[2] || 0));
    });
  }

  context.fillStyle = "#333";

  // if (res.time) context.fillText(`${res.time | 0}ms`, 10, 10);
  // if (res.epoch) context.fillText(res.epoch, 10, 30);

  return pos;
  return context.canvas;
}

export async function _view(DOM, width, height, data) {
  console.log("_view 243", DOM, width, height);

  // const d3 = await import("https://cdn.skypack.dev/d3@7");
  // const d = await import("https://cdn.skypack.dev/umap-js@1.3.3");
  // const R = await import("https://cdn.skypack.dev/seedrandom");

  // const seedrandom = R.default;
  // seedrandom('hello.', { global: true });
  // seedrandom(593335098, { global: true });
  seedrandom("593335098", { global: true });
  console.log("LINE296 R", Math.random(), Math.random());
  console.log("390 _view os.freemem", os.freemem());

  // const height = width * 0.8;
  // const context = DOM.context2d(width, height);
  // const points = Array.from({ length: 33 }, () => Array.from({ length: 92 }, Math.random));
>>>>>>> master
  const UMAP = d.UMAP;

  return _chart(d3, UMAP, DOM, width, height, data);

}
