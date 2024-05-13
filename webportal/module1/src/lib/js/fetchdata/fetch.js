import { env } from '$env/dynamic/public';

/**
 * @param {string} query
 */
function urlValidateCellorId(query) {
    return `${env.PUBLIC_API_ENDPOINT_DBQUERY}?t=validatecellorid&v=${encodeURIComponent(query)}`;
}
/**
 * @param {string} query
 */
export async function fetchValidateCellorId(query) {
    if (query) {
        const url = urlValidateCellorId(query)
        return await fetch(url)
            .then(async (res) => {
                if (!res.ok) {
                    throw new Error(query);
                }
                return await res.json();
            })
            .catch((e) => {
                throw new Error(`fetchValidateCellorId:${query}:${e}`);
            });
    }
}

/**
 * @param {string} query
 */
function urlTreeForCellLine(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERY + '?t=cellline&v=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchTreeForCellLine(query) {
    if (query) {
        const url = urlTreeForCellLine(query)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchTreeForCellLine query', query, e);
                throw e;
            });
    }
}


/**
 * @param {string} query
 */
function urlTreeForCellId(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERY + '?t=tree&v=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchTreeForCellId(query) {
    if (query) {
        const url = urlTreeForCellId(query)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchTreeForCellId query', query, e);
                throw e;
            });
    }
}



/**
 * @param {string} query
 */
function urlGrowthCurveData(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERYGROWTHCURVE + '?id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchGrowthCurveData(query) {
    if (query) {
        const url = urlGrowthCurveData(query)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchGrowthCurveData query', query, e);
                throw e;
            });
    }
}


/**
 * @param {string} query
 */
function urlTimetableData(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERYTIMETABLE + '?id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchTimetableData(query) {
    if (query) {
        const url = urlTimetableData(query)
        const data = await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                throw e;
            });
        return data;
    }
}





/**
 * @param {string} query
 * @param {string} perspective
 */
function urlGenotypePieData(query, perspective) {
    return env.PUBLIC_API_ENDPOINT_DBQGENOTYPEINFO + '?info=pie&perspective=' + encodeURIComponent(perspective) + '&id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 * @param {string} perspective
 */
export async function fetchGenotypePieData(query, perspective) {
    if (query && perspective) {
        const url = urlGenotypePieData(query, perspective)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchGenotypePieData query', query, perspective, e);
                throw e;
            });
    }
}


/**
 * @param {string} query
 * @param {string} perspective
 */
function urlGenotypeUMAPData(query, perspective) {
    const url = env.PUBLIC_API_ENDPOINT_DBQGENOTYPEINFO + '?info=umap&perspective=' + encodeURIComponent(perspective) + '&id=' + encodeURIComponent(query);
    return url;
}
/**
 * @param {string} query
 * @param {string} perspective
 */
export async function fetchGenotypeUMAPData(query, perspective) {
    if (query && perspective) {
        const url = urlGenotypeUMAPData(query, perspective)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchGenotypeUMAPData query', query, perspective, e);
                throw e;
            });
    }
}


/**
 * @param {string} query
 * @param {string} perspective
 */
function urlGenotypeHEATMAPData(query, perspective) {
    return env.PUBLIC_API_ENDPOINT_DBQGENOTYPEINFO + '?info=heatmap&perspective=' + encodeURIComponent(perspective) + '&id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 * @param {string} perspective
 */
export async function fetchGenotypeHEATMAPData(query, perspective) {
    if (query && perspective) {
        const url = urlGenotypeHEATMAPData(query, perspective)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('urlGetGenotypeHEATMAPData query', query, perspective, e);
                throw e;
            });
    }
}




/**
 * @param {string} query
 */
function urlHarvestWithGenotypicInfo(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERYHARVESTWITHGENOTYPICINFO + '?id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchHarvestWithGenotypicInfo(query) {
    if (query) {
        const url = urlHarvestWithGenotypicInfo(query)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchHarvestWithGenotypicInfo query', query, e);
                throw e;
            });
    }
}


/**
 * @param {string} query
 */
function urlHarvestWithMorphologyInfo(query) {
    return env.PUBLIC_API_ENDPOINT_DBQUERYHASMORPHOLOGYPERSPECTIVE + '?id=' + encodeURIComponent(query);
}
/**
 * @param {string} query
 */
export async function fetchHarvestWithMorphologyInfo(query) {
    if (query) {
        const url = urlHarvestWithMorphologyInfo(query)
        return await fetch(url)
            .then(async (res) => {
                return await res.json();
            })
            .catch((e) => {
                console.log('fetchHarvestWithMorphologyInfo query', query, e);
                throw e;
            });
    }
}