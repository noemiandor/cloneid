/** @type {import('../$types').PageLoad} */


export const load = ({ params }) => {
    return {
        k: params.a,
        v: params.b,
    }
}
