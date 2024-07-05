<script>
	/** @type {import('./$types').PageData} */
	export let data;

	import { browser } from '$app/environment';
	import ChartContainerGenoPie from '$lib/charts/containers/ChartContainerGenoPie.svelte';
	import {
		completionPie,
		completionUMAP,
		loadingIndicatorToggle,
		modalOpenPie
	} from '$lib/storage/local/stores.js';
	import { Loading, Tile } from 'carbon-components-svelte';
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
		if ($completionPie == true) {
			$loadingIndicatorToggle = false;
		}
	}
	$completionPie = false;
	$completionUMAP = false;

	function completion() {
		$modalOpenPie = true;
		$completionPie = true;
	}
	$modalOpenPie = false;
</script>

<Loading active={$loadingIndicatorToggle} />
{#if cellId}
	<h4><strong>{perspective} - {cellId}</strong></h4>
	<Tile>
		<ChartContainerGenoPie
			{cellId}
			{perspective}
			{completion}
			size="fitwidth"
		/>
	</Tile>
{/if}
