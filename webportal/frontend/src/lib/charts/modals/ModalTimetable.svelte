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

	export let closeDialog = () => {};
	export let openDialog = () => {};

	import { browser } from '$app/environment';
	import ChartContainerTimetable from '../containers/ChartContainerTimetable.svelte';
	import { loadingIndicatorToggle, modalOpenTimeTable } from '$lib/storage/local/stores.js';
	import { Column, Grid, Modal, OutboundLink, Row } from 'carbon-components-svelte';
	import { Carbon } from 'carbon-icons-svelte';
	import { onMount } from 'svelte';

	onMount(() => {
		if (browser) {
			$modalOpenTimeTable = false;
		}
	});
	function completion() {
		$modalOpenTimeTable = true;
		$loadingIndicatorToggle = false;
	}
	$modalOpenTimeTable = false;
	$: HASH = `${UUID}-${cellId}-${perspective}-MTT`;
</script>

<Modal
	modalHeading="TimeTable - {cellId}"
	passiveModal
	bind:open={$modalOpenTimeTable}
	on:open={() => {
		if (typeof openDialog == 'function') { openDialog(); }
	}}
	on:close={() => {
		if (typeof closeDialog == 'function') { closeDialog(); cellId = null;}
	}}
	hasScrollingContent
>
	<Grid>
		<Row>
			<Column>
				{#key HASH}
					<ChartContainerTimetable
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
	<OutboundLink href="/fullScreen/timetable/{cellId}" icon={Carbon} target="_blank">Open in new window</OutboundLink>
</Modal>
