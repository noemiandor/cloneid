/**
 * @param {any} subClones
 */
export function pie(subClones) {
    const pieData = Object.keys(subClones)
        .flatMap((k) => {
            if(Object.keys(subClones[k]).length > 0) 
            return ({ name: k, value: Object.keys(subClones[k]).length });
        });

        return pieData;
}
