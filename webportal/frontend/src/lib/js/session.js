import {
    set_store_value
} from "svelte/internal";

import { browser } from '$app/environment';
import {
    loginIconBGColor,
    showModalLogin,
    showModalLoginInvalid,
    showModalLogout,
    userIsLoggedIn,
    userName,
    userPassword
} from '$lib/storage/local/stores.js';
import { green } from '@carbon/colors';
import "svelte/internal/disclose-version";

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
    if (browser) {
        if (sessionGet('cloneid') == 'on') {
            set_store_value(userIsLoggedIn, $userIsLoggedIn = true, $userIsLoggedIn);
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
