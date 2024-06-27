import { env } from "$env/dynamic/public";
export var need_to_log = 9;
export var localLevel = 0;
/**
 * @param {number} x
 */
export function setGlobalDebugLevel(x) {
    need_to_log = x;
}
export function setLocalDebugLevel(x) {
    localLevel = x;
}
export function console_log(...args) {
    if (
        (need_to_log > parseInt(env.PUBLIC_GLOBAL_DEBUG_LEVEL))
        ||
        (args[0] && (typeof args[0] == 'string') && args[0].startsWith('DEBUG') && (localLevel = parseInt(args[0].substring(5))) > parseInt(env.PUBLIC_LOCAL_DEBUG_LEVEL))
    ) {
        const STAMP = ((new Date()).getTime()).toString();
        if (localLevel > 0) { args.shift(); }
        console.log("LOG", STAMP, '::', ...args);
    }
}
