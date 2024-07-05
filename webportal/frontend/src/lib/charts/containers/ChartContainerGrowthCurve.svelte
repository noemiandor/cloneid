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
	import * as Plot from '@observablehq/plot';
	import { Button, InlineLoading, OutboundLink, Tile, TooltipIcon } from 'carbon-components-svelte';
	import { Carbon, CloseOutline } from 'carbon-icons-svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';
	import { fetchGrowthCurveData } from '../../js/fetchdata/fetch';

	/**
	 * @param {{ data: any[]; }} p
	 */
	function sanityzeAndSort(p) {
		return p.data
			.map((/** @type {{ date: string | number | Date; cellCount: any; }} */ x) => {
				const d = new Date(x.date);
				return {
					Date: d,
					CellCount: x.cellCount
				};
			})
			.sort((/** @type {{ Date: Date; }} */ a, /** @type {{ Date: Date; }} */ b) => {
				return a.Date.getTime() - b.Date.getTime();
			});
	}

	async function drawChartGrowthCurve() {
		fetchGrowthCurveData(cellId).then((rawdata) => {
			const data = sanityzeAndSort(rawdata);

			const po = {
				height: containerHeight,
				width: containerWidth,
				marginLeft: 40,
				marginRight: 10,
				marginBottom: 30,
				marginTop: 10,
				color: { legend: true },
				symbol: { legend: true },
				inset: 10,
				marks: [
					Plot.frame({ fill: '#e0e0e077' }),
					Plot.gridY({ stroke: 'white', strokeOpacity: 1 }),
					Plot.gridX({ stroke: 'white', strokeOpacity: 1 }),
					Plot.line(data, {
						x: 'Date',
						y: 'CellCount',
						stroke: '#10101077',
						marker: 'circle-stroke',
						tip: true,
						strokeLinecap: 'round'
					}),
					Plot.axisY({
						anchor: 'left',
						ticks: 5,
						tickSpacing: 0,
						rotate: 0,
						tickRotate: 0,
						tickFormat: '~e'
					})
				]
			};
			const plot = Plot.plot(po);
			ContainerDomId?.firstChild?.remove();
			ContainerDomId?.append(plot);
		});
	}

	async function drawChart() {
		if (cellId)
			await drawChartGrowthCurve().then(async () => {
				loaded = true;
				if (typeof completion == 'function') {
					completion(true);
				}
			});
	}
	async function _redraw(ds) {
		if (browser) {
			if (windowHeight && windowWidth) {
				ContainerDomId?.firstChild?.remove();
				await drawChart();
			}
		}
	}
	let waitingforredraw = false;
	async function redraw() {
		if (waitingforredraw) {
			return;
		}
		if (browser && cellId && windowHeight && windowWidth) {
			waitingforredraw = true;
			await new Promise((r) => setTimeout(r, 1000));
			ContainerDomId?.firstChild?.remove();
			await drawChart();
			waitingforredraw = false;
		}
	}

	onMount(async () => {
		// size = 'xs';
		// size = 'sq';
		// size = 'sm';
		// size = 'md';
		// size = 'max';
		// size = 'modal';
		// size = 'fitwidth';
		size = 'fit';
		redraw();
	});
	$: loaded = false;
	$: unik = HASH + cellId + perspective + 'CGGC';

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
			href="/fullScreen/growthcurve/{cellId}"
			on:click={(e) => {
			}}
		>
			<TooltipIcon tooltipText="Open in new Window">
				<OutboundLink href="/fullScreen/growthcurve/{cellId}" icon={Carbon} target="_blank">
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
			{:else if size == 'fit'}
				<div
					bind:this={ContainerDomId}
					class="xyz1"
					style="--wdivsize:{wdivsize};--hdivsize:{hdivsize};"
				></div>
			{:else}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="overflow:hidden;height:{dimensions[size].h}px;min-height:{dimensions[size]
						.h}px;min-width:{dimensions[size].w}px;"
				></div>
			{/if}
		</div>
	{/key}
</Tile>

<style>
	.xyz1 {
		width: calc(var(--wdivsize) * 1px);
		height: calc(var(--hdivsize) * 1px);
		margin: 0px;
		padding: 0px;
	}
</style>
