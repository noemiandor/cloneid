<script>
	/** @type {import('./$types').PageData} */
	export let data;
	import ChartContainerTimetable from '$lib/charts/containers/ChartContainerTimetable.svelte';
	import '@ibm/plex/scss/ibm-plex.scss';
	import { Tile } from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
	let cellId = data.cellLineOrId;
</script>

{#if cellId}
	<Tile>
		<h4>TimeTable - <strong>{cellId}</strong></h4>
		<ChartContainerTimetable {cellId} size={'fitwidth'} id={null} />
	</Tile>
{/if}
