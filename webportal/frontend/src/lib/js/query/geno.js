import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
<<<<<<< HEAD
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';
=======
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import { count } from '../count';
>>>>>>> master

/**
 * @param {string} origin
 * @param {string} perspective
 */
export async function genomicProfileForSubPopulation(origin, perspective, forHeatMap, use_cache = true) {

<<<<<<< HEAD
    use_cache = false;
=======
    // use_cache = false;
>>>>>>> master

    const originShardString = `${origin}-${perspective}-genomicProfileForSubPopulation`;
    const keysShardString = `keys-${origin}-${perspective}-genomicProfileForSubPopulation`;

<<<<<<< HEAD
    let sps = null;

    let subClones_keys = [];
    var subProfiles = {};
    const whichPerspective = new Perspectives(perspective);
    const subClones = await Manager.display(origin, whichPerspective);
    subClones_keys = Object.keys(subClones).map((k) => {
        const v = k.split("_ID"); return { long: k, short: parseInt(v[1]) };
    });
=======
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::14::", origin, perspective, originShardString);

    // return [];
    let sps = null;
    // sps = await getShard(originShardString);
    // if (sps && count(sps) > 0) {
    //     console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::SPS::19::", originShardString, sps.length ? sps.length : Object.keys(sps).length);
    //     // console.log("genomicProfileForSubPopulation::getShard::sps::");
    //     return sps;
    // }
    // console.log("19::genomicProfileForSubPopulation::origin", keysShardString);
    // sps = await getShard(keysShardString)
    //     .then(async (keys) => {
    //         console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::SPS::28::", keys);
    //         // console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::SPS::28::", keys.length ? keys.length : Object.keys(keys).length); //, subClones);
    //         if (keys && keys.length > 0) {
    //             let subP = Object();
    //             for (let i = 0; i < keys.length; i++) {
    //                 const longId = keys[i].long;
    //                 const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
    //                 console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::SPS::34::", i, profileShardString); //, subClones);
    //                 subP[longId] = await getShard(profileShardString);
    //             }
    //             return subP;
    //         } else {
    //             return null;
    //         }
    //     })
    //     .catch((e) => {
    //         console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::ERROR::", e);
    //         sps = null;
    //     });
    // console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::GETSHARD::SPS::48::", keysShardString, sps);
    // // if (sps && count(sps)>0) {
    // if (sps) {
    //     return sps;
    // }

    let subClones_keys = [];
    var subProfiles = {};
    // CALLED by R getSubclones<-function(cloneID_or_sampleName,whichP="GenomePerspective"){
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::55::", origin, perspective);
    const whichPerspective = new Perspectives(perspective);
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::58::", whichPerspective);

    let subClones = {};
    let intOrigin = parseInt(origin);
    if (Number.isNaN(intOrigin)) {
        subClones = await Manager.displaySample(origin, whichPerspective);
    } else {
        subClones = await Manager.displayId(parseInt(origin), whichPerspective);
    }
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::58::", count(subClones), subClones);
    // if (count(subClones)<5)
    subClones_keys = Object.keys(subClones).map((k) => {
        const v = k.split("_ID");
        const n = parseInt(v[1]);
        if (Number.isNaN(n)) {
            return { long: k };
        } else {
            return { long: k, short: parseInt(v[1]) };
        }
    });
    // console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::62::", count(subClones_keys));
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::62::", subClones_keys);
>>>>>>> master
    const savedShared1 = await saveShard(keysShardString, subClones_keys);
    if (!savedShared1) {
        throw keysShardString;
    }

    for (let i = 0; i < subClones_keys.length; i++) {
        const longId = subClones_keys[i].long;
        const shortId = subClones_keys[i].short;
<<<<<<< HEAD
        await Manager.profiles(shortId, whichPerspective, false)
            .then(async (subProfile) => {
                const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
=======
        console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::90::", i, subClones_keys[i]);
        await Manager.profiles(shortId?shortId:longId, whichPerspective, false)
            .then(async (subProfile) => {
                const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
        console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::91::", subProfile, profileShardString);
>>>>>>> master
                const savedShared2 = await saveShard(profileShardString, subProfile);
                if (!savedShared2) {
                    throw profileShardString;
                }
                subProfiles[longId] = subProfile;
<<<<<<< HEAD
            }
=======
                console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::78::", longId, subProfiles);
            }
                // ,
                //     (rejected) => {
                //         console.log("111::genomicProfileForSubPopulation::origin", rejected);
                //         throw rejected;
                //         return {};
                //     }
>>>>>>> master
            )
            .catch((e) => {
                console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::CATCH::89::", e);
            })
            ;
    }
    ;
<<<<<<< HEAD
    const savedShared3 = await saveShard(originShardString, subProfiles);
    if (!savedShared3) {
        console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
=======
    console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::94::", count(subProfiles), subProfiles);
    // console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::94::", subProfiles);
    // console.log("951::genomicProfileForSubPopulation::origin", subClones_keys.length);
    if (count(subProfiles)) {
        const savedShared3 = await saveShard(originShardString, subProfiles);
        if (!savedShared3) {
            console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
        }
>>>>>>> master
    }


    return subProfiles;
}


/**
 * @param {string} origin
 * @param {Perspectives} perspective
 */
export async function _genomicProfileForSubPopulation(origin, perspective, use_cache = true) {
<<<<<<< HEAD
    const originShardString = `${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
    if (use_cache) {
        let error = false;
        const sps = await getShard(originShardString)
            .then(async (sps) => {
                if (sps) {
                    return sps;
                } else {
                    const keysShardString = `keys-${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
                    return await getShard(keysShardString)
                        .then(async (keys) => {
=======

    const originShardString = `${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
    console.log("10::GENOJS::genomicProfileForSubPopulation::origin", origin, "perspective", perspective, "use_cache", use_cache, "originShardString", originShardString);
    if (1 == 1 && use_cache) {
        let error = false;
        const sps = await getShard(originShardString)
            .then(async (sps) => {
                console.log("16::genomicProfileForSubPopulation::origin", sps);
                if (sps) {
                    console.log("18::genomicProfileForSubPopulation::origin", sps);
                    return sps;
                } else {
                    const keysShardString = `keys-${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
                    console.log("19::genomicProfileForSubPopulation::origin", keysShardString);
                    return await getShard(keysShardString)
                        .then(async (keys) => {
                            console.log("22::genomicProfileForSubPopulation::origin", origin, perspective.name(), keysShardString, keys); //, subClones);
>>>>>>> master
                            if (keys && keys.length > 0) {
                                let subP = {};
                                for (let i = 0; i < keys.length; i++) {
                                    const longId = keys[i].long;
                                    const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
<<<<<<< HEAD
                                    await getShard(profileShardString)
                                        .then((sp) => {
=======
                                    console.log("28::genomicProfileForSubPopulation::origin", i, profileShardString); //, subClones);
                                    await getShard(profileShardString)
                                        .then((sp) => {
                                            console.log("31::genomicProfileForSubPopulation::origin", Object.keys(sp).length, longId, profileShardString, i);
>>>>>>> master
                                            subP[longId] = sp;
                                        })
                                        .catch((e) => {
                                            use_cache = false;
<<<<<<< HEAD
=======
                                            console.log("35::genomicProfileForSubPopulation::Catch", e);
                                            // throw e;
>>>>>>> master
                                        });
                                }
                                return subP;
                            } else {
                                use_cache = false;
                                error = true;
                                return {};
<<<<<<< HEAD
                            }
=======
                                // throw "no keys";
                            }
                            // console.log("43::genomicProfileForSubPopulation::origin", origin, perspective.name(), keysShardString, keys); //, subClones);
                            // error = true;
                            // // throw error;
                            // return {};
>>>>>>> master
                        })
                        .catch((e) => {
                            console.log("49::genomicProfileForSubPopulation::Catch", e);
                            error = true;
<<<<<<< HEAD
=======
                            // throw error;
                            // return {};
>>>>>>> master
                        });
                }
            }).catch((e) => {
                error = true;
                console.log("57::genomicProfileForSubPopulation::Catch", e);
<<<<<<< HEAD
            });
        if (!error) { return sps; }
    }
    console.log("63::genomicProfileForSubPopulation::Catch");
    let subClones_keys = [];
    var subProfiles = {};
    if (!use_cache) {
        console.log("68::genomicProfileForSubPopulation::origin", origin, perspective.name()); //, subClones);
        const subClones = await Manager.display(origin, perspective);
        subClones_keys = Object.keys(subClones).map((k) => {
            const v = k.split("_ID"); return { long: k, short: parseInt(v[1]) };
        });
=======
                // throw e;
                // return {};
            });
        // throw sps;
        if (!error) { return sps; }
    }
    // throw origin;
    console.log("63::genomicProfileForSubPopulation::Catch");
    let subClones_keys = [];
    var subProfiles = {};
    if (0 == 1 || !use_cache) {
        // if (true) {
        console.log("68::genomicProfileForSubPopulation::origin", origin, perspective.name()); //, subClones);
        // throw "809::genomicProfileForSubPopulation::origin";
        // CALLED by R getSubclones<-function(cloneID_or_sampleName,whichP="GenomePerspective"){
        const subClones = await Manager.display(origin, perspective);

        subClones_keys = Object.keys(subClones).map((k) => {
            const v = k.split("_ID"); return { long: k, short: parseInt(v[1]) };
        });
        console.log("76::genomicProfileForSubPopulation::origin", subClones_keys); //, subClones);
>>>>>>> master
        const keysShardString = `keys-${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
        const savedShared1 = await saveShard(keysShardString, subClones_keys);
        if (!savedShared1) {
            return {};
        }
<<<<<<< HEAD
        for (let i = 0; i < subClones_keys.length; i++) {
            const longId = subClones_keys[i].long;
            const shortId = subClones_keys[i].short;
=======
        // console.log("944::genomicProfileForSubPopulation::origin", origin, perspective.name(), keysShardString, subClones_keys); //, subClones);
        // return subProfiles

        // console.log("886::genomicProfileForSubPopulation::origin", subClones_keys);
        // throw "880::genomicProfileForSubPopulation::origin";
        for (let i = 0; i < subClones_keys.length; i++) {
            const longId = subClones_keys[i].long;
            const shortId = subClones_keys[i].short;
            // const startTime = new Date();
            // const subProfile =
>>>>>>> master
            await Manager.profiles(shortId, perspective, false)
                .then(async (subProfile) => {
                    const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
                    const savedShared2 = await saveShard(profileShardString, subProfile);
                    if (!savedShared2) {
                        throw profileShardString;
                    }
<<<<<<< HEAD
                    subProfiles[longId] = subProfile;
                },
                    (rejected) => {
                        throw rejected;
                    }
                )
                .catch((e) => {
                    console.error(e)
                    throw e;
=======
                    console.log("98::genomicProfileForSubPopulation::origin", longId, Object.keys(subProfile).length);
                    subProfiles[longId] = subProfile;
                },
                    (rejected) => {
                        console.log("111::genomicProfileForSubPopulation::origin", rejected);
                        throw rejected;
                        return {};
                    }
                )
                .catch((e) => {
                    console.log("117::genomicProfileForSubPopulation::origin", e);
                    console.error(e)
                    throw e;
                    return {};
>>>>>>> master
                })
                ;
        }
        ;
<<<<<<< HEAD
        const savedShared3 = await saveShard(originShardString, subProfiles);
        if (!savedShared3) {
            console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
=======
        console.log("951::genomicProfileForSubPopulation::origin", subClones_keys.length);
        const savedShared3 = await saveShard(originShardString, subProfiles);
        if (!savedShared3) {
            console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
            // throw originShardString;
>>>>>>> master
        }
    }
    return subProfiles;
}