/** @type {import('../$types').PageLoad} */


export const load = ({ params }) => {
    return {
        cellLineOrId: params.cellLineOrId,
        perspective: params.perspective,
    }
}
