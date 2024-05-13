<script>
	/** @type {import('./$types').PageData} */
	export let data;
	import ChartContainerGrowthCurve from '$lib/charts/containers/ChartContainerGrowthCurve.svelte';
	import '@ibm/plex/scss/ibm-plex.scss';
	import { Content, Tile } from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
	let cellId = data.cellLineOrId;
</script>

{#if cellId}
<Content>
	<Tile>
		<h4>Growth curve - <strong>{cellId}</strong></h4>
		<ChartContainerGrowthCurve {cellId} size={'fit'} id={null} />
	</Tile>
</Content>
{/if}
