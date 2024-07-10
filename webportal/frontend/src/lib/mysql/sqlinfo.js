import { SQLHOST, SQLHOSTDOCKER, SQLPORT, SQLPORTDOCKER } from '$env/static/private';

import { runningInDocker } from './runningInDocker';
import { retrieveUser } from './sqluser';


export function sqlhost() {
    if(runningInDocker()){
        return SQLHOSTDOCKER;
    }else{
        return SQLHOST;
    }
}

export function sqlport() {
    if(runningInDocker()){
        return SQLPORTDOCKER;
    }else{
        return SQLPORT;
    }
}


export async function sqluser(u) {
    const j = await retrieveUser(u);
    console.log('sqluser', j);
    return (j.u).toString();
}

export async function sqlpswd(u) {
    const j = await retrieveUser(u);
    console.log('sqluser', j);
    return j.p;
}