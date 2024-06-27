import { spawn } from "node:child_process";
import fs, { mkdirSync } from "node:fs";
import { logerror, logmessage, normalisePathForQueue, normalisePathFromComponents } from "./path.js/index.js";


export async function spawn(app, queue, id, payload) {
    if (!(payload)) {
        return false;
    }
    if (!(app && queue && id && payload)) {
        return false;
    }
    logmessage(["spawnjob", app, queue, id, payload]);
    console.log(payload);

    let subprocess;
    const exe = payload.p.spawn.shift();
    const exe_args = payload.p.spawn;
    logmessage(["SPAWN", exe, exe_args]);
    subprocess = spawn(exe, exe_args);
    let exitcode = 0;
    let errorcode = 0;
    let waitforexit = true;
    subprocess.on('error', (err) => {
        waitforexit = false;
        errorcode = err.errno;
        logerror(['SPAWN ERROR', app, queue, id, errorcode]);
    });
    subprocess.on('close', async (code) => {
        exitcode = code;
        waitforexit = false;
        logmessage(['SPAWN CLOSE', app, queue, id, exitcode]);
    });
    const spawnOutputDir = normalisePathFromComponents([normalisePathForQueue(app, 'spawn'), id]);;
    mkdirSync(spawnOutputDir, { recursive: true });
    const stdoutfile = normalisePathFromComponents([spawnOutputDir, 'stdout.txt']);
    const stderrfile = normalisePathFromComponents([spawnOutputDir, 'stderr.txt']);
    const notififile = normalisePathFromComponents([spawnOutputDir, 'notification.txt']);
    const messgefile = normalisePathFromComponents([spawnOutputDir, 'messages.txt']);
    subprocess.stdout.on('data', (data) => {
        logmessage(['stdout', data]);
        const n1 = /\[INFO\][^\d]+(\d+)%\|/.exec(data.toString());
        if (n1 && n1[1]) { fs.writeFileSync(notififile, `images ${n1[1]}% analyzed\n`); }

        const n2 = /\[INFO\] >>>> (.+)/.exec(data.toString());
        if (n2 && n2[1]) { fs.writeFileSync(notififile, `info: ${n2[1]}\n`); }

        const n3 = /\[NOTIF\]::(.+)/.exec(data.toString());
        if (n3 && n3[1]) { fs.writeFileSync(notififile, `${n3[1]}\n`); }

        const n4 = /Getting the cell count .../.exec(data.toString());
        if (n4 && n4[1]) { fs.writeFileSync(notififile, `${n4[1]}\n`); }

        const n5 = /Getting cell visualization .../.exec(data.toString());
        if (n5 && n5[1]) { fs.writeFileSync(notififile, `${n5[1]}\n`); }

        const n6 = /\[MESSG\]::(.+)/.exec(data.toString());
        if (n6 && n6[1]) { fs.writeFileSync(messgefile, `${n6[1]}\n`, { flag: "a+" }); }

        fs.writeFileSync(stdoutfile, data, { flag: "a+" });
    });
    subprocess.stderr.on('data', (data) => {
        logmessage(['stderr', data]);
        const n1 = /(\d+)%\|/.exec(data.toString());
        if (n1 && n1[1]) { fs.writeFileSync(notififile, `count and visualization ${n1[1]}% analyzed\n`); }

        const n3 = /\[NOTIF\]::(.+)/.exec(data.toString());
        if (n3 && n3[1]) { fs.writeFileSync(notififile, `${n3[1]}\n`); }

        fs.writeFileSync(stderrfile, data, { flag: "a+" });
    });
    while (waitforexit) {
        logmessage(['waiting', exe, (new Date()).getTime()]);
        await new Promise((r) => setTimeout(r, 1000));
    }
    logmessage(['done', exe, (new Date()).getTime()]);
    if (errorcode !== 0) return false;
    return true;
}
