import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';

/**
 * @param {string} origin
 * @param {string} perspective
 */
export async function genomicProfileForSubPopulation(origin, perspective, forHeatMap, use_cache = true) {

    use_cache = false;

    const originShardString = `${origin}-${perspective}-genomicProfileForSubPopulation`;
    const keysShardString = `keys-${origin}-${perspective}-genomicProfileForSubPopulation`;

    let sps = null;

    let subClones_keys = [];
    var subProfiles = {};
    const whichPerspective = new Perspectives(perspective);
    const subClones = await Manager.display(origin, whichPerspective);
    subClones_keys = Object.keys(subClones).map((k) => {
        const v = k.split("_ID"); return { long: k, short: parseInt(v[1]) };
    });
    const savedShared1 = await saveShard(keysShardString, subClones_keys);
    if (!savedShared1) {
        throw keysShardString;
    }

    for (let i = 0; i < subClones_keys.length; i++) {
        const longId = subClones_keys[i].long;
        const shortId = subClones_keys[i].short;
        await Manager.profiles(shortId, whichPerspective, false)
            .then(async (subProfile) => {
                const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
                const savedShared2 = await saveShard(profileShardString, subProfile);
                if (!savedShared2) {
                    throw profileShardString;
                }
                subProfiles[longId] = subProfile;
            }
            )
            .catch((e) => {
                console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::CATCH::89::", e);
            })
            ;
    }
    ;
    const savedShared3 = await saveShard(originShardString, subProfiles);
    if (!savedShared3) {
        console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
    }


    return subProfiles;
}


/**
 * @param {string} origin
 * @param {Perspectives} perspective
 */
export async function _genomicProfileForSubPopulation(origin, perspective, use_cache = true) {
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
                            if (keys && keys.length > 0) {
                                let subP = {};
                                for (let i = 0; i < keys.length; i++) {
                                    const longId = keys[i].long;
                                    const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
                                    await getShard(profileShardString)
                                        .then((sp) => {
                                            subP[longId] = sp;
                                        })
                                        .catch((e) => {
                                            use_cache = false;
                                        });
                                }
                                return subP;
                            } else {
                                use_cache = false;
                                error = true;
                                return {};
                            }
                        })
                        .catch((e) => {
                            console.log("49::genomicProfileForSubPopulation::Catch", e);
                            error = true;
                        });
                }
            }).catch((e) => {
                error = true;
                console.log("57::genomicProfileForSubPopulation::Catch", e);
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
        const keysShardString = `keys-${origin}-${perspective.name()}-genomicProfileForSubPopulation`;
        const savedShared1 = await saveShard(keysShardString, subClones_keys);
        if (!savedShared1) {
            return {};
        }
        for (let i = 0; i < subClones_keys.length; i++) {
            const longId = subClones_keys[i].long;
            const shortId = subClones_keys[i].short;
            await Manager.profiles(shortId, perspective, false)
                .then(async (subProfile) => {
                    const profileShardString = `profile-${longId}-genomicProfileForSubPopulation`;
                    const savedShared2 = await saveShard(profileShardString, subProfile);
                    if (!savedShared2) {
                        throw profileShardString;
                    }
                    subProfiles[longId] = subProfile;
                },
                    (rejected) => {
                        throw rejected;
                    }
                )
                .catch((e) => {
                    console.error(e)
                    throw e;
                })
                ;
        }
        ;
        const savedShared3 = await saveShard(originShardString, subProfiles);
        if (!savedShared3) {
            console.log("954::genomicProfileForSubPopulation::origin:NOTSAVED", subClones_keys.length);
        }
    }
    return subProfiles;
}