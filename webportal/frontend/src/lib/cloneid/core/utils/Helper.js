// const fs = require('fs');

export class Helper {
    static get FILE_SEPARATOR() {
        return require('path').sep;
    }

    static get LINE_SEPARATOR() {
        return '\n';
    }

    static get TAB() {
        return '\t';
    }

    static get NEWLINE() {
        return '\n';
    }

    static firstIndexOf(o, array) {
        for (let i = 0; i < array.length; i++) {
            if (array[i] === o) {
                return i;
            }
        }
        return -1;
    }

    static replaceLast(s, p, new_p) {
        s = s.substring(0, s.lastIndexOf(p)) + s.substring(s.lastIndexOf(p), s.length()).replace(p, new_p);
        return s;
    }

    static getReader(cbsin) {
        try {
            let r = fs.readFileSync(cbsin, 'utf8').split(/\r?\n/);

            let c = 0;
            let h = r.shift();
            while (h !== undefined && h.startsWith('#')) {
                h = r.shift();
                c++;
            }

            while (c > 0) {
                r.shift();
                c--;
            }

            return r;
        } catch (e) {
            console.error(e);
            return null;
        }
    }
    static isDouble(string) {
        try {
            parseFloat(string);
            return true;
        } catch (e) {
            return false;
        }
    }

    static fillArray(length, numberVal) {
        let a = new Array(length);
        a.fill(numberVal);
        return a;
    }

    static fillArray(startNo, stopNo) {
        let a = new Array(stopNo - startNo);
        for (let i = startNo; i < stopNo; i++) {
            a[i - startNo] = i;
        }
        return a;
    }

    static double2byte(values) {
        let bytes = [];
        for (let d of values) {
            let buffer = new ArrayBuffer(8);
            let view = new DataView(buffer);
            view.setFloat64(0, d);
            bytes.push(...new Uint8Array(buffer));
        }
        return bytes;
    }

    static string2byte(values) {
        let bytes = [];
        for (let str of values) {
            for (let i = 0; i < str.length; i++) {
                let code = str.charCodeAt(i);
                bytes.push(code >>> 8);
                bytes.push(code & 0xFF);
            }
            let newline = "\n";
            for (let i = 0; i < newline.length; i++) {
                let code = newline.charCodeAt(i);
                bytes.push(code >>> 8);
                bytes.push(code & 0xFF);
            }
        }
        return bytes;
    }
    static byte2double(asBytes) {
        let dubs = [];
        let bin = new Uint8Array(asBytes);
        let view = new DataView(bin.buffer);
        for (let i = 0; i < bin.length; i += 8) {
            let value = view.getFloat64(i);
            dubs.push(value);
        }
        return dubs;
    }

    static parseDouble(string) {
        if (Helper.isDouble(string)) {
            return parseFloat(string);
        } else {
            return NaN;
        }
    }

    static toDouble(rs) {
        let d = new Array(rs.length);
        for (let i = 0; i < rs.length; i++) {
            d[i] = rs[i];
        }
        return d;
    }

    static count(childrensSizes, precision) {
        let spfreq = new Map();
        for (let d_ of childrensSizes) {
            let d = Math.round(d_ / precision) * precision;
            if (spfreq.has(d)) {
                spfreq.set(d, spfreq.get(d) + 1);
            } else {
                spfreq.set(d, 1);
            }
        }
        return spfreq;
    }

    static sapply(lines, fun, arg) {
        let out = new Array(lines.length);
        for (let i = 0; i < lines.length; i++) {
            if (fun === "split") {
                out[i] = lines[i].split(arg);
            }
        }
        return out;
    }

    static apply(lines, fun, arg) {
        let out = new Array(lines.length);
        for (let i = 0; i < lines.length; i++) {
            if (fun === "get") {
                out[i] = lines[i][arg];
            }
        }
        return out;
    }
    static byte2String(bytes) {
        let dubs = [];
        let bin = new Uint8Array(bytes);
        let view = new DataView(bin.buffer);
        let l = "";
        let c = '\0';
        for (let i = 0; i < bin.length; i += 2) {
            c = view.getInt16(i);
            if (c === 10) {
                dubs.push(l.trim());
                l = "";
            } else {
                l += String.fromCharCode(c);
            }
        }
        let object = dubs;
        return object;
    }

    static string2int(split) {
        let o = new Array(split.length);
        for (let i = 0; i < split.length; i++) {
            o[i] = parseInt(split[i]);
        }
        return o;
    }

    static string2double(split) {
        let o = new Array(split.length);
        for (let i = 0; i < split.length; i++) {
            o[i] = parseFloat(split[i]);
        }
        return o;
    }
}
