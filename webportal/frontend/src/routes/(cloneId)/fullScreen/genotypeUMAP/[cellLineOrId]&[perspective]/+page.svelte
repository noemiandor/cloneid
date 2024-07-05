<script>
	/** @type {import('./$types').PageData} */
	export let data;

	import { browser } from '$app/environment';
	import ChartContainerGenoUMAP from '$lib/charts/containers/ChartContainerGenoUMAP.svelte';
	import {
		completionPie,
		completionUMAP,
		loadingIndicatorToggle
	} from '$lib/storage/local/stores.js';
	import '@ibm/plex/scss/ibm-plex.scss';
	import { Column, Grid, Loading, Row, Tile } from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';

	import { onMount } from 'svelte';
	let cellId = data.cellLineOrId;
	let perspective = data.perspective;

	onMount(() => {
		if (browser) {
			$loadingIndicatorToggle = true;
			$completionPie = false;
			$completionUMAP = false;
		}
	});

	$: {
		if ($completionPie && $completionUMAP) {
			$loadingIndicatorToggle = false;
		}
	}
	$completionPie = true;
	$completionUMAP = false;

	function completionfUMAP() {
		$completionUMAP = true;
	}
	function completionfPie() {
		$completionPie = true;
	}
</script>

<Loading active={$loadingIndicatorToggle} />
{#if cellId}
	<h4><strong>Genotype Information - {cellId}</strong></h4>
	<Tile>
		<Grid>
			<Row>
				<Column>
					{perspective}
					<ChartContainerGenoUMAP
						{cellId}
						{perspective}
						completion={completionfUMAP}
						size="md"
					/>
				</Column>
			</Row>
		</Grid>
	</Tile>
{/if}
