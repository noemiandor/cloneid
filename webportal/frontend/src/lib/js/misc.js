export function decoderesponse(x) {
    const kv = JSON.parse(x.data);
    const k = kv[0];
    let d = {};
    for (let [k1, v1] of Object.entries(k)) {
        d[k1] = kv[v1];
    }
    return d;
}
