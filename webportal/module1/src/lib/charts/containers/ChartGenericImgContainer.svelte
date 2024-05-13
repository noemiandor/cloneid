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
	 * @type {((arg0: number[]) => void)| null}
	 */
	export const containerDimension = null;

	/**
	 * @type {((arg0: boolean) => void)| null}
	 */
	export let completion = null;

	/**
	 * @type {number|null}
	 */
	export let id = null;

	/**
	 * @type {((arg0: number[]) => void)| null}
	 */
	export let remove = null;

	/**
	 * @type {string}
	 */
	export let size = 'xs';

	/**
	 * @type {string}
	 */
	export let HASH = '';

	/**
	 * @type {number}
	 */
	let windowWidth;
	/**
	 * @type {number}
	 */
	let windowHeight;
	/**
	 * @type {number}
	 */
	let containerWidth;
	/**
	 * @type {number}
	 */
	let containerHeight;

	/**
	 * @type {HTMLDivElement}
	 */
	let ContainerDomId;

	import { browser } from '$app/environment';
	import { dimensions } from '$lib/js/paneldimensions';
	import { Button, InlineLoading, OutboundLink, Tile, TooltipIcon } from 'carbon-components-svelte';
	import { Carbon, CloseOutline } from 'carbon-icons-svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';

	/**
	 * @param {string} item
	 */
	async function callBackendScriptGen(item) {
		if (!item) {
			return [];
		}
		let formData = new FormData();
		formData.append('item', JSON.stringify(item));
		const result = await fetch('?/callbackendscriptgen', {
			method: 'POST',
			body: formData
		})
			.then(async (res) => {
				const result = await res.json();
				console.log('result', result);
				const data = JSON.parse(result.data);
				const keys = data[0];
				return JSON.parse(data[keys['result']]);
			})
			.catch((e) => {
				console.log('callbackendscriptgen', e);
			})
			;
		return result.result;
	}

	// const exampleData = [
	// 	[1, 2, 3],
	// 	[4, 5, 6],
	// 	[7, 8, 9]
	// ];

	async function drawGenericImg() {
		ContainerDomId?.firstChild?.remove();
		const child = document.createElement('img');
		child.src = '/CiD.png';
		child.width = '150';
		child.height = '50';
		ContainerDomId?.append(child);
	}

	async function drawChart() {
		if (cellId)
			await drawGenericImg().then(async () => {
				if (typeof completion == 'function') {
					completion(true);
				}
				loaded = true;
			});
	}
	let waitingforredraw = false;
	async function redraw() {
		if (waitingforredraw) {
			return;
		}
		if (browser && windowHeight && windowWidth) {
			waitingforredraw = true;
			console.log('CURVE::GROWTH::REDRAW');
			ContainerDomId?.firstChild?.remove();
			await new Promise((r) => setTimeout(r, 1500));
			await drawChart();
			waitingforredraw = false;
		}
	}
	onMount(async () => {
		redraw();
	});
	$: loaded = false;
	$: unik = HASH + cellId + perspective + 'GENERIC';
	let divsize;
	let wdivsize;
	let hdivsize;

	$: {
		wdivsize = containerWidth * 0.99;
		hdivsize = (2 * wdivsize) / 3;
		redraw();
	}
</script>

<svelte:window
	bind:innerHeight={windowHeight}
	bind:innerWidth={windowWidth}
	on:resize={throttle(redraw, 1000)}
/>
<Tile
	style="margin:0px;padding:0px;border: 0rem outset black;
outline: 0.05rem solid #7772;
border-radius: 0px;
font: bold 0.1rem sans-serif;
outline-offset: 0.05rem;_text-align:right;margin-bottom:0px;"
>
	{#if id != null}
		<Button
			style="margin:0px;padding:0px;"
			size="small"
			kind="ghost"
			tooltipPosition="right"
			tooltipAlignment="end"
			iconDescription="Close"
			icon={CloseOutline}
			on:click={() => {
				if (typeof remove === 'function') {
					if (id) remove(id);
				}
			}}
		/>

		<Button
			size="small"
			kind="ghost"
			type="submit"
			href="/fullScreen/generic/{cellId}/${perspective}"
			on:click={(e) => {
			}}
		>
			<TooltipIcon tooltipText="Open in new Window">
				<OutboundLink href="/fullScreen/generic/{cellId}" icon={Carbon} target="_blank">
					<span style="font-size:x-small;">{cellId} </span>
				</OutboundLink>
			</TooltipIcon>
		</Button>
	{/if}
	{#if !loaded}
		<InlineLoading status="active" description="Loading data..." />
	{/if}
	{#key unik}
		<div bind:clientWidth={containerWidth} bind:clientHeight={containerHeight}>
			{#if size == 'modal'}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="
					overflow-y:auto;
					overflow-x:visible;
					height:{dimensions[size].domh};
					width:{dimensions[size].domw};
					"
				></div>
			{:else if size == 'fitwidth' || size == 'fullscreen' || size == 'max'}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="
				overflow-y:auto;
				min-height:80vh;
				width:{dimensions[size].domw};
				"
				></div>
			{:else}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="font: bold 2.1rem sans-serif;overflow-y:auto;height:{dimensions[size]
						.h}px;min-height:{dimensions[size].h}px;min-width:{dimensions[size].w}px;"
				>
					<img
						src="data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
						style="height:{dimensions[size].h}px;min-height:{dimensions[size]
							.h}px;min-width:{dimensions[size].w}px;"
					/>
				</div>
			{/if}
		</div>
	{/key}
</Tile>

<style>
	.xyz1 {
		width: calc(var(--wdivsize) * 1px);
		height: calc(var(--hdivsize) * 1px);
		overflow-y: auto;
		overflow-x: visible;
		margin: 0px;
		padding: 0px;
	}
</style>
