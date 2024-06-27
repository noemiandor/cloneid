
import * as JSsha512 from 'js-sha512';


import { set_store_value } from "svelte/internal";
import { get } from "svelte/store";

import { certifieduser, userName } from "../storage/local/stores";

import { dev } from '$app/environment';


export function getUserHash() {
    let userHash;
    let $userName;

    const certified_user = get(certifieduser);

    if (certified_user) {
        set_store_value(userName, $userName = certified_user, $userName);
    } else {
        set_store_value(userName, $userName = 'anonymous', $userName);
    }

    const user_name = get(userName);

    if (dev) {
        userHash = user_name;
    } else {
        userHash = JSsha512.sha512(user_name);
    }
    return userHash;
    return 'anonymous';
}