/**
 * @param {{} | string | any[]} X
 */
export function count(X){
    if (!X) return null;
    return (X && X.length) ? X.length : (Object.keys(X)? Object.keys(X).length : null);
}


