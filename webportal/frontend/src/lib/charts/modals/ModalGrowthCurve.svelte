<script>
	/**
	 * @type {string}
	 */
	export let cellId;
	/**
	 * @type {string}
	 */
	export let perspective = '';
	/**
	 * @type {string}
	 */
	 export let UUID;

	export let closeDialog = ()=>{};
	export let openDialog = ()=>{};
	
	import { browser } from '$app/environment';
	import ChartContainerGrowthCurve from '$lib/charts/containers/ChartContainerGrowthCurve.svelte';
	import { loadingIndicatorToggle, modalOpenGrowthCurve } from '$lib/storage/local/stores.js';
	import { Column, Grid, Modal, OutboundLink, Row } from 'carbon-components-svelte';
	import { Carbon } from 'carbon-icons-svelte';
	import { onMount } from 'svelte';

	onMount(() => {
		if (browser) {
			$modalOpenGrowthCurve = false;
		}
	});
	function completion() {
		$modalOpenGrowthCurve = true;
		$loadingIndicatorToggle = false;
	}
	$modalOpenGrowthCurve = false;
	$: HASH = `${UUID}-${cellId}-${perspective}-MGC`;
</script>

<Modal
modalHeading="Growth Curve - {cellId}"
passiveModal
bind:open={$modalOpenGrowthCurve}
on:open={() => { if(typeof openDialog == 'function'){openDialog();} }}
on:close={()=>{ if(typeof closeDialog == 'function'){closeDialog(); cellId = null;} }}
>
	<Grid>
		<Row>
			<Column>
				{#key HASH}
					<ChartContainerGrowthCurve
						{cellId}
						{perspective}
						{completion}
						size={'modal'}
						{HASH}
						id={null}
					/>
				{/key}
			</Column>
		</Row>
	</Grid>

	<br />
	<OutboundLink href="/fullScreen/growthcurve/{cellId}" icon={Carbon} target="_blank">Open fullScreen</OutboundLink>
</Modal>
