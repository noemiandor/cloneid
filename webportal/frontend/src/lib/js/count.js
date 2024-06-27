/**
 * @param {{} | string | any[]} X
 */
export function count(X){
    return X ? (X.length ? X.length : Object.keys(X).length) : undefined;
}


