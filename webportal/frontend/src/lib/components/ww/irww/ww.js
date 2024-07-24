import { fetch_retrieveJob } from '@/lib/jobs/fetch';

const job = {
    txid: '1234567890',
    apid: '1234567890',
    quid: '1234567890',
    cntr: 0,
    timr: 0,
    pltm: 1000,
}

onmessage = async (x) => {
    if (x.data.msg === "init") {
        job.txid = x.data.data.txid;
        job.apid = x.data.data.apid;
        job.quid = x.data.data.quid;
        job.pltm = x.data.data.pltm;
        postMessage({ww:'INIT'});
        startPolling();
    }
    if (x.data.msg === "stop") {
        stopPolling();
        postMessage({ww:'STOP'});
    }
};

async function jobPoll() {
    job.cntr++;
    const j = await fetch_retrieveJob({ a: job.apid, q: job.quid, i: job.txid, operation:'multiple' });
    if (j) {
        if (j.q === 'done') {
            stopPolling();
            postMessage({ww:'DONE'});
			return;
		}        
        j.ww = job.cntr;
        postMessage(j);
    }
}

function startPolling() {
    job.cntr = 0;
    job.timr = setInterval(jobPoll, job.pltm);
}
function stopPolling() {
    clearInterval(job.timr);
}


export { };
