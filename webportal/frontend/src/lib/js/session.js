import {
    set_store_value
} from "svelte/internal";

import { browser } from '$app/environment';
import {
    certifieduser,
    loginIconBGColor,
    showModalLogin,
    showModalLoginInvalid,
    showModalLogout,
    userIsLoggedIn,
    userName,
    userPassword,
} from '$lib/storage/local/stores.js';
import { green } from '@carbon/colors';
import "svelte/internal/disclose-version";

// import { counter } from "./stores";
/**
 * @param {string} field
 * @param {string} value
 */
export function sessionStore(field, value) {
    if (browser) {
        const s = window.sessionStorage.setItem(field, value);
    }
}
/**
 * @param {string} field
 */
export function sessionClear(field) {
    if (browser) {
        const s = window.sessionStorage.removeItem(field);
    }
}
/**
 * @param {string} field
 */
export function sessionGet(field) {
    if (browser) {
        const s = window.sessionStorage.getItem(field);
        return s;
    }
    return null;
}
/**
 * @param {boolean} l
 */
export function setIconBG(l) {
    let $loginIconBGColor;
    const bg = l ? green[40] : '#555e';
    set_store_value(loginIconBGColor, $loginIconBGColor = 'background-color: ' + bg + ';', $loginIconBGColor);
}
export function setIconBGifExistingSession() {
    let $userIsLoggedIn;
    let $certifieduser;
    if (browser) {
        if (sessionGet('cloneid') == 'on') {
            set_store_value(userIsLoggedIn, $userIsLoggedIn = true, $userIsLoggedIn);
            set_store_value(certifieduser, $certifieduser = sessionGet('user'), $certifieduser);
            setIconBG(true);
        } else {
            setIconBG(false);
        }
    }
}

export function cleanSlate() {
    let $showModalLogin;
    let $showModalLogout;
    let $showModalLoginInvalid;
    let $userIsLoggedIn;
    let $userName;
    let $userPassword;
    let $loginIconBGColor;
    set_store_value(userIsLoggedIn, $userIsLoggedIn = false, $userIsLoggedIn);
    set_store_value(showModalLogin, $showModalLogin = false, $showModalLogin);
    set_store_value(showModalLogout, $showModalLogout = false, $showModalLogout);
    set_store_value(showModalLoginInvalid, $showModalLoginInvalid = false, $showModalLoginInvalid);
    set_store_value(userName, $userName = '', $userName);
    set_store_value(userPassword, $userPassword = '', $userPassword);
    set_store_value(loginIconBGColor, $loginIconBGColor = '', $loginIconBGColor);
}


export function authorized() {
    if (browser) {
        if (sessionGet('module2') == 'on') {
            return true;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

export function setAuthorized() {
    if (browser) {
        sessionStore('module2', 'on')
    }
}

export function clearAuthorized() {
    if (browser) {
        sessionClear('module2');
    }
}


// export function add() {
//     var counterRef = get(counter);
//     counter.set(counterRef + 1);
// }
