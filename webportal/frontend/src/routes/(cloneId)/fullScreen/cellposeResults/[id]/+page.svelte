<script>
	/** @type {import('./$types').PageData} */
	export let data;
	import '@ibm/plex/scss/ibm-plex.scss';
	import 'carbon-components-svelte/css/g10.css';
	let id = data.id;
	import CellposeResults from '@/routes/(cloneId)/module2/3_d/components/CellposeResults.svelte';
</script>

{#if id}
	<CellposeResults {id}/>
{/if}
