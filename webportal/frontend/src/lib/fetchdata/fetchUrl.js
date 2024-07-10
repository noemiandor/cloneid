/**
 * @param {string | URL | Request} baseurl
 * @param {string} method
 * @param {HTMLFormElement | undefined} data
 */

import { get } from "svelte/store";
import { userName } from "../storage/local/stores";


export async function fetchUrl(baseurl, method, data) {
  const value = get(userName);
  if(data.username){
    throw data;
  }
  data.username = value;

  const formData = new FormData();
  const params = new URLSearchParams();
  
  for (let field of Object.entries(data)) {
    const [k, v] = field;
    formData.append(k, v);
    params.append(k, v);
  }

  if (method.toLowerCase() === 'get'){
    const fullUrl = `${baseurl}?${params}`;
    return fetch(fullUrl);
    const get = await fetch(`${baseurl}?${params}`);
    console.log("get", await get.text(), get);
  }
  else if (method.toLowerCase() === 'post'){
    return fetch(baseurl, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }
  else if (method.toLowerCase() === 'params'){
    return fetch(baseurl, {
      method: 'POST',
      body: params
    });
  }
}
