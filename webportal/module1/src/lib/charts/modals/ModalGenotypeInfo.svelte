<script>
	/**
	 * @type {string}
	 */
	export let cellId;
	/**
	 * @type {string[]}
	 */
	export let perspectives;
	/**
	 * @type {string}
	 */
	export let UUID;

	export let closeDialog = () => {};
	export let openDialog = () => {};

	import {
		completionPie,
		completionUMAP,
		loadingIndicatorToggle,
		modalOpenGenotypeInfo
	} from '$lib/storage/local/stores.js';
	import { Column, Grid, Modal, OutboundLink, Row } from 'carbon-components-svelte';
	import { browser } from '$app/environment';
	import ChartContainerGenoUMAP from '$lib/charts/containers/ChartContainerGenoUMAP.svelte';
	import { onMount } from 'svelte';
	import { Carbon } from 'carbon-icons-svelte';

	onMount(() => {
		if (browser) {
			$completionPie = false;
			$completionUMAP = false;
		}
	});
	function completion() {
		$loadingIndicatorToggle = false;
		$modalOpenGenotypeInfo = true;
	}
	$: HASH = `${UUID}-${cellId}`;
</script>

<Modal
	bind:open={$modalOpenGenotypeInfo}
	passiveModal
	modalHeading="Genotype Information - {cellId}"
	size="lg"
	on:open={() => { if (typeof openDialog == 'function') { openDialog(); } }}
	on:close={() => { if (typeof closeDialog == 'function') { closeDialog(); cellId = null; } }}
>
	<Grid>
		<Row>
			{#each perspectives as perspective}
				<Column>
					<h5>{perspective}</h5>
					{#key `${HASH}-${perspective}`}
						<ChartContainerGenoUMAP
							{cellId}
							{perspective}
							{completion}
							size={'modal'}
							HASH={`${HASH}-${perspective}-U`}
							id={null}
						/>
					{/key}
				</Column>
			{/each}
		</Row>
	</Grid>
	<br />
	<OutboundLink href="/fullScreen/genotypeInfo/{cellId}&{perspectives.join('_')}"  icon={Carbon} target="_blank" >Open in new window</OutboundLink >
</Modal>
