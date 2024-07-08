import * as d from 'umap-js';
import * as d3 from 'd3';
import * as os from 'os';
import seedrandom from 'seedrandom';

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


function __distances(d3, vectors, distanceType) {
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
  };
  const umap = new UMAP(cfg);
  if (labels) umap.setSupervisedProjection(labels);
  const N = Math.sqrt(distances.length);

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
  let classify = d3.scaleOrdinal(d3.schemeCategory10);

  classify = d3
    .scaleOrdinal()
    .domain(rawdata.map((d) => d.subClone))
    .range(d3.quantize((t) => d3.interpolateSpectral(t * 0.8 + 0.1), rawdata.length).reverse());

  const data = rawdata.map(d => {
    d.color = classify(d.subClone);
    d.label = d.subProfile;
    return d;
  });

  const labels = __labels(d3, data);
  const numericfields = __numericfields(d3, data);
  const vectors = __vectors(d3, data, numericfields);
  const distances = __distances(d3, vectors, 'euclidean');

  const res = __fit(d3, UMAP, distances, labels)
  const pos = res.result || vectors;

  const columns = data.columns || Object.keys(data[0]);


  var color0 = d3
    .scaleLinear()
    .range(["red", "lime"])
    .domain([0, vectors.length])



  // Create the color scale.
  var color = d3.scaleOrdinal()
    .domain(data.map(d => d.subClone))
    .range(d3.quantize(t => d3.interpolateSpectral(t * 0.8 + 0.1), data.length).reverse())
  return pos.map((d, i) => {
    const row = ({ x: d[0], y: d[1], color: color(i), subclone: data[i].subClone });
    return row;
  });


  function coords(i) {
    return [x(pos[i][0] || 0), y(pos[i][1] || pos[i][0] || 0)];
  }

}

export async function _view(DOM, width, height, data) {

  seedrandom("593335098", { global: true });

  const UMAP = d.UMAP;

  return _chart(d3, UMAP, DOM, width, height, data);

}
