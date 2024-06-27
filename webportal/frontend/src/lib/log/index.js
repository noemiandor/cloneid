
/**
 * @param {[string]} a
 */

export function logmessage(a) {
  if (!(a && a.length)) return;
  console.log(["INFO", ...a].join('::'));
}
/**
 * @param {[string]} a
 */

export function logerror(a) {
    if (!(a && a.length)) return;
    console.error(a.join('::'));
  }
  