<<<<<<< HEAD
=======
import compare from 'just-compare';

>>>>>>> master
/**
 * @param {any} subClones
 */
export function pie(subClones) {
<<<<<<< HEAD
=======
    // return Object.keys(subClones)
    // // .filter((k) => Object.keys(subClones[k]).length > 0)
    //     .map((k) => {
    //         return ({ name: k, value: Object.keys(subClones[k]).length });
    //     });
    // return
>>>>>>> master
    const pieData = Object.keys(subClones)
        .flatMap((k) => {
            if(Object.keys(subClones[k]).length > 0) 
            return ({ name: k, value: Object.keys(subClones[k]).length });
        });

        return pieData;
}
