<script>
	/** @type {import('./$types').PageData} */
	export let data;

	import { browser } from '$app/environment';
	import ChartContainerGenoUMAP from '$lib/charts/containers/ChartContainerGenoUMAP.svelte';
	import { completionUMAP, loadingIndicatorToggle } from '$lib/storage/local/stores.js';
	import '@ibm/plex/scss/ibm-plex.scss';
	import { Column, Content, Grid, Loading, Row, Tile } from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
	import { onMount } from 'svelte';

	let cellId = data.cellLineOrId;
	let perspectives = data.perspective.split('_');

	onMount(() => {
		if (browser) {
			$loadingIndicatorToggle = true;
			$completionUMAP = false;
		}
	});
	$: {
		if ($completionUMAP == true) {
			$loadingIndicatorToggle = false;
		}
	}
	$completionUMAP = false;
	function completion() {
		$completionUMAP = true;
	}
</script>

<Loading active={$loadingIndicatorToggle} />

{#if cellId != ''}
<Content>
	<h4><strong>Genotype Information - {cellId}</strong></h4>
	<Tile>
		<Grid>
			<Row>
				{#each perspectives as perspective}
					<Column>
						<strong>{perspective}</strong>
						<ChartContainerGenoUMAP {cellId} {perspective} {completion} size="fit" />
					</Column>
				{/each}
			</Row>
		</Grid>
	</Tile>
</Content>
{/if}
