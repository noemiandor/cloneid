import compare from 'just-compare';

/**
 * @param {any} subClones
 */
export function pie(subClones) {
    // return Object.keys(subClones)
    // // .filter((k) => Object.keys(subClones[k]).length > 0)
    //     .map((k) => {
    //         return ({ name: k, value: Object.keys(subClones[k]).length });
    //     });
    // return
    const pieData = Object.keys(subClones)
        .flatMap((k) => {
            if(Object.keys(subClones[k]).length > 0) 
            return ({ name: k, value: Object.keys(subClones[k]).length });
        });

        return pieData;
}
