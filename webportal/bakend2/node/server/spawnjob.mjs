import { spawn } from "node:child_process";
import fs, { existsSync, readFileSync, mkdirSync } from "node:fs";
import { logerror, logmessage, normalisePathForQueue, normalisePathFromComponents, normalisePathForCellposeDir } from "./misc.mjs";
import { sqlupdate } from "./sqlupdate2.mjs";
import * as JSsha512 from 'js-sha512';

export async function spawnjob(app, queue, id, payload) {
    if (!(payload)) {
        return false;
    }

    if (!(app && queue && id && payload)) {
        return false;
    }
    logmessage(["spawnjob", app, queue, id, payload]);
    let subprocess;

    const exe = payload.p.spawn.shift();
    const exe_args = payload.p.spawn;

    const needsCleanup = (payload.sqluser === 'anonymous' ? true : (payload.sqluser === JSsha512.sha512('anonymous') ? true : false));
    const timelapse = (payload.timelapse ? payload.timelapse : 5);
    logmessage(["SPAWN", exe, exe_args.join(' ')]);
    console.log("PAYLOAD", payload);
    console.log("payload.sqluser", payload.sqluser);
    console.log("needsCleanup", needsCleanup);
    console.log("timelapse", timelapse);
    
    let exitcode = 0;
    let errorcode = 0;
    let waitforexit = true;

    const spawnOutputDir = normalisePathFromComponents([normalisePathForQueue(app, 'spawn'), id]);
    mkdirSync(spawnOutputDir, { recursive: true });
    const pushdOutputDir = normalisePathFromComponents([spawnOutputDir, 'pushed']);
    mkdirSync(pushdOutputDir, { recursive: true });

    const fpaths = {};

    [
        'ABRT',
        'AFIQ',
        'AFIR',
        'DONE',
        'INFO',
        'JSON',
        'MESG',
        'MSQL',
        'NTIF',
        'PRNT',
        'QUIT',
        'RSLT',
        'TIMT',
        'VARS',
        'WRNG',
    ].forEach((header) => {
        fpaths[header] = normalisePathFromComponents([spawnOutputDir, header.toLowerCase() + '.txt']);
    });

    [
        'stdout',
        'stderr',
    ].forEach((header) => {
        fpaths[header] = normalisePathFromComponents([spawnOutputDir, header.toLowerCase() + '.txt']);
    });

    const imagesets = exe_args.slice(-4)[0];
    const imageset = exe_args.slice(-3)[0];
    logmessage(["SPAWN", "imagesets", imagesets]);
    logmessage(["SPAWN", "imageset", imageset]);
    console.log([normalisePathForCellposeDir(), imagesets, imageset])
    const cellsegmentationsDir = normalisePathFromComponents([normalisePathForCellposeDir(), imagesets, imageset.toString()]);;
    mkdirSync(cellsegmentationsDir, { recursive: true });


    [
        'input',
        'output',
        'tmp',
        'results',
    ].forEach((dir) => {
        fpaths[dir] = normalisePathFromComponents([cellsegmentationsDir, dir]);
        mkdirSync(fpaths[dir], { recursive: true });
    });


    process.env['CELLSEGMENTATIONS_INDIR'] = fpaths['input'];
    process.env['CELLSEGMENTATIONS_OUTDIR'] = fpaths['output'];
    process.env['TMP_DIR'] = fpaths['tmp'];
    process.env['RESULTS_DIR'] = fpaths['results'];
    process.env['RUNNINGINBACKEND'] = "TRUE";
    process.env['TXID'] = id;
    process.env['TXID_DIR_AFI'] = spawnOutputDir;


    subprocess = spawn(exe, exe_args);

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


    const RGX = [

        // cellpose
        { r: '([0-9]+)%\\|', e: 'NTIF', c: (x) => { return `count and visualization ${x}% analyzed\n`; }, },
        // cellpose
        { r: '\\[INFO\\] ([0-9]+)%\\|', e: 'NTIF', c: (x) => { return `images ${x}% analyzed\n`; }, },
        // cellpose
        { r: '\\[INFO\\] >>>> (.+)', e: 'NTIF', c: (x) => { return `${x}\n`; }, },
        // cellpose
        { r: 'Getting the cell count ...', e: 'NTIF', c: (x) => { return `${x}\n`; }, },
        // cellpose
        { r: 'Getting cell visualization ...', e: 'NTIF', c: (x) => { return `${x}\n`; }, },
        { r: `\\[ABRT\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'ABRT', c: (x) => { return `${x}\n`; }, },
        { r: '\\[AFIR\\]::(.+)', e: 'AFIR', c: (x) => { return `${x}\n`; }, },
        { r: `\\[AFIQ\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'AFIQ', c: (x) => { return `${x}\n`; }, },
        { r: `\\[DONE\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'DONE', c: (x) => { return `${x}\n`; }, },
        { r: `\\[INFO\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'INFO', c: (x) => { return `${x}\n`; }, },
        { r: `\\[JSON\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'JSON', c: (x) => { return `${x}\n`; }, },
        { r: `\\[MESG\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'MESG', c: (x) => { return `${x}\n`; }, },
        { r: `\\[MSQL\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'MSQL', c: (x) => { return `${x}\n`; }, },
        { r: `\\[NTIF\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'NTIF', c: (x) => { return `${x}\n`; }, },
        { r: `\\[PRNT\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'PRNT', c: (x) => { return `${x}\n`; }, },
        { r: `\\[QUIT\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'QUIT', c: (x) => { return `${x}\n`; }, },
        { r: `\\[RSLT\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'RSLT', c: (x) => { return `${x}\n`; }, },
        { r: `\\[TIMT\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'TIMT', c: (x) => { return `${x}\n`; }, },
        { r: `\\[VARS\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'VARS', c: (x) => { return `${x}\n`; }, },
        { r: `\\[WRNG\\]::${id}::[0-9 -:]+::(.+)::${id}`, e: 'WRNG', c: (x) => { return `${x}\n`; }, },
    ];
    const RGP = RGX.map((x) => {
        return ({ r: new RegExp(x.r), e: x.e, c: x.c, });
    });

    function regextrans(data) {
        const ds = data.toString();
        fs.writeFileSync(fpaths['stdout'], ds, { flag: "a+" });
        for (const y of RGP) {
            const r = (y.r).exec(ds);
            if (r && r[1]) {
                const dt = new Date();
                const ts = dt.getTime().toString() + dt.getMilliseconds().toString();
                const pushed = normalisePathFromComponents(
                    [
                        pushdOutputDir,
                        ts + '_' + (y.e).toLowerCase() + '.txt'
                    ]
                );
                fs.writeFileSync(fpaths[y.e], (y.c)(r[1]));
                fs.writeFileSync(pushed, (y.c)(r[1]));
                continue;
            }
        }
    }

    // console.log("RGP",RGP);
    subprocess.stdout.on('data', regextrans);
    subprocess.stderr.on('data', regextrans);

    let pingdelta = -1;
    let lastping = 0;
    let pingcount = 0;
    let deadpings = 0;
    let killed = false;
    const pingf = normalisePathFromComponents([spawnOutputDir, 'ping.txt']);
    while (waitforexit) {
        // logmessage(['waiting', exe, (new Date()).getTime()]);

        if (existsSync(pingf)) {
            try {
                const ping = JSON.parse(readFileSync(pingf).toString());
                if (pingdelta === -1) {
                    lastping = ping.date - 1000;
                }
                pingdelta = ping.date - lastping;
                lastping = ping.date;
                if (pingdelta === 0) {
                    deadpings++;
                }
                logmessage(['waiting', exe, id, (new Date()).getTime(), pingdelta]);
            } catch (err) {
                logmessage(['waiting', exe, id, (new Date()).getTime(), err]);
            }
        } else {
            deadpings++;
            logmessage(['NO PING', exe, id, (new Date()).getTime(), deadpings]);
        }

        if (deadpings > 15) {
            killed = subprocess.kill()
            logmessage(['DEADPRC', exe, id, (new Date()).getTime(), "KILL THE ZOMBIES", killed]);
            if (killed) break;
        }

        await new Promise((r) => setTimeout(r, 1000));
    }
    if (needsCleanup===true) {
        var cleanupAction = async function () {
            const appname = exe_args.slice(-1)[0];
            let sqlresult;
            switch (appname) {
                case 'i2c': // import morphologyperspective
                    sqlresult = await sqlupdate('Perspective', id);
                    break;
                case 'ivu': // invitroutils seed harvest passaging
                    sqlresult = await sqlupdate('Passaging', id);
                    break;

                default:
                    break;
            }
            logmessage(['SPAWN cleanupAction', app, queue, id, sqlresult, appname]);
        };
        logmessage(['SPAWN cleanupAction in '+timelapse+'mn', app, queue, id, killed]);
        setTimeout(cleanupAction, timelapse * 60 * 1000);
    }
    return (errorcode === 0);
}
