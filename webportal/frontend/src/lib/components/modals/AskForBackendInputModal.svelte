<script>
	import { fetch_afianswer } from '@/lib/jobs/fetch';
	import { loadingIndicatorToggle } from '@/lib/storage/local/stores';
	import CellposeResults from '@/routes/(cloneId)/module2/home/components/CellposeResults.svelte';
	import { Checkbox, Column, Grid, Modal, RadioButton, RadioButtonGroup, Row, Tile } from 'carbon-components-svelte';

	/**
	 * @type {boolean}
	 */
	export let show;
	/**
	 * @type {string}
	 */
	export let seg;
	export let txid;
	export let prompt;
	export let retry;
	/**
	 * @type {string[]}
	 */
	export let options;
	/**
	 * @type {string}
	 */
	 export let message;
	/**
	 * @type {string}
	 */
	export let type;

	/**
	 * @type {string}
	 */
	let selected = undefined;

	let waitforprocessing = false;

	$: showmodal = show && !waitforprocessing;

	let confirmed = false;
	let confirmdisabled = false;
	/**
	 * @type {string[]}
	 */
	let checkBoxValues = [];

	function logVars() {
		const x = {
			checkBoxValues: checkBoxValues,
			confirmdisabled: confirmdisabled,
			confirmed: confirmed,
			message: message,
			options: options,
			prompt: prompt,
			retry: retry,
			selected: selected,
			show: show,
			showmodal: showmodal,
			txid: txid,
			type: type,
			waitforprocessing: waitforprocessing
		};
		// console.log('X', x);
	}
</script>

<Modal
	hasForm
	size="lg"
	preventCloseOnClickOutside
	bind:open={show}
	modalHeading={prompt ? prompt : ''}
	primaryButtonText="Confirm"
	primaryButtonDisabled={confirmdisabled}
	on:click
	on:close={async (e) => {
		logVars();
		if (!confirmed) {
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			await new Promise((res) => setTimeout(res, 300)); // Wait a while
			show = true;
		}
		// console.log('CLOSE', e);
	}}
	on:click:button--secondary
	on:open
	on:submit={async (e) => {
		$loadingIndicatorToggle = true;
		logVars();
		// console.log('E', e);
		switch (type) {
			case 'C':
				selected = '#' + checkBoxValues.join(', ');
				confirmed = true;
				break;
			case 'R':
				if (!selected) {
					confirmed = !true;
					e.preventDefault();
					e.stopPropagation();
					e.stopImmediatePropagation();
					await new Promise((res) => setTimeout(res, 300)); // Wait a while
					show = true;
					return;
				} else {
					confirmed = true;
				}
				break;
			default:
				break;
		}
		show = false;
		await fetch_afianswer({ a: 'm2.cellpose', i: txid, txid: txid, selected: selected });
		await new Promise((res) => setTimeout(res, 3000)); // Wait a while
	}}

			<hr />
	{#if type === 'R'}
		{#if message}
			<Tile>{@html message}</Tile>
		{/if}
		<RadioButtonGroup name="options" bind:selected orientation="vertical">
			{#each options as option, i}
				<RadioButton labelText={option} value={(i + 1).toString()} />
			{/each}
		</RadioButtonGroup>
	{/if}
	{#if type === 'C'}
		<CellposeResults
			exclude={checkBoxValues}
			picsonly={true}
			id={seg}
		/>
		{#if message}
			<Tile>{@html message}</Tile>
		{/if}

		<Grid style="width:50%">
			<Row>
					{#each options as option, i}
				<Column>
						<Checkbox
							bind:group={checkBoxValues}
							labelText={option}
							value={option}
							on:check={(e) => {
								if (checkBoxValues.length === options.length) {
									confirmdisabled = true;
								} else {
									confirmdisabled = false;
								}
							}}
						/>
				</Column>
					{/each}
			</Row>
		</Grid>
	{/if}
</Modal>