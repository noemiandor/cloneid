<script>
	/**
	 * @type {string}
	 */
	export let cellId;

	/**
	 * @type {string}
	 */
	export let perspective;

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
	import {
		Button,
		InlineLoading,
		Loading,
		OutboundLink,
		Tile,
		TooltipIcon
	} from 'carbon-components-svelte';
	import { Carbon, CloseOutline } from 'carbon-icons-svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';
	import { fetchTimetableData } from '../../js/fetchdata/fetch';

		let timetableData = null;
	async function chartTimetable() {

		if (timetableData && timetableData.data) {
			const rows = timetableData.data;
			let h = containerHeight;
			const w = containerWidth;
			const rh = rows.length < 5 ? 80 : 30;
			let vm = 0;
			const bm = 30;
			if (rh * rows.length < containerHeight - bm) {
				vm = (containerHeight - rh * rows.length) / 2;
			} else {
				h = rh * rows.length;
			}
			const po =
				size == 'sm' || size == 'x'
					? {
							height: h,
							width: w,
							marginTop: vm,
							marginRight: 40,
							marginBottom: vm + bm,
							marginLeft: 100,
							x: { type: 'utc' },
							y: { type: 'band' },
							inset: 10,
							marks: [
								Plot.frame({ stroke: '#f0f0f0', fill: '#f0f0f033' }),
								Plot.gridY({ stroke: '#f0f0f0', strokeOpacity: 1 }),
								Plot.gridX({ stroke: '#f0f0f0', strokeOpacity: 1 }),
								Plot.axisY({ fontSize: 0 }),
								Plot.barX(rows, {
									x1: 'start',
									x2: 'end',
									y: 'seed',
									sort: { y: 'x1' },
									dx: 0,
									fill: '#10101033',
									stroke: '#10101066'
								}),
								Plot.text(rows, {
									x: 'end',
									y: 'seed',
									text: 'dhms',
									textAnchor: 'start',
									dx: 2,
									fontSize: 8,
									tip: true
								}),
								Plot.axisX({
									fontSize: 8
								}),
								Plot.axisY({
									fontSize: 7,
									tickPadding: 10,
									insetLeft: 2,
									label: '',
									lineWidth: 10
								})
							]
					  }
					: {
							height: h,
							width: w,
							marginTop: vm,
							marginRight: 100,
							marginBottom: vm + bm,
							marginLeft: 150,
							x: { type: 'utc' },
							y: { type: 'band' },
							inset: 10,
							marks: [
								Plot.frame({ stroke: '#f0f0f0', fill: '#f0f0f033' }),
								Plot.gridY({ stroke: '#f0f0f0', strokeOpacity: 1 }),
								Plot.gridX({ stroke: '#f0f0f0', strokeOpacity: 1 }),
								Plot.barX(rows, {
									x1: 'start',
									x2: 'end',
									y: 'seed',
									sort: { y: 'x1' },
									dx: 0,
									fill: '#a0a0a033',
									stroke: '#10101066'
								}),
								Plot.text(rows, {
									x: 'end',
									y: 'seed',
									text: 'dhms',
									textAnchor: 'start',
									dx: 2,
									fontSize: 10,
									tip: true
								}),
								Plot.axisX({
									fontSize: 10
								}),
								Plot.axisY({
									fontSize: 8,
									tickPadding: 10,
									insetLeft: 2,
									label: '',
									lineWidth: 15
								})
							]
					  };
			const plot = Plot.plot(po);
			console.log(plot);
			ContainerDomId?.firstChild?.remove();
			ContainerDomId?.append(plot);
		}
	}

	/**
	 * @param {string} query
	 */
	async function drawTimetable() {
		if (cellId)
			await chartTimetable().then(() => {
				loaded = true;
				if (typeof completion == 'function') {
					completion(true);
				}
			});
	}

	let waitingforredraw = false;
	async function redraw() {
		if (waitingforredraw) {
			return;
		}
		if (!timetableData) {
			return;
		}
		if (browser && cellId && windowHeight && windowWidth) {
			waitingforredraw = true;
			await new Promise((r) => setTimeout(r, 1500));
			await drawTimetable();
			waitingforredraw = false;
		}
	}
	async function redraw0() {
		if (browser && cellId && windowHeight && windowWidth) {
			await drawTimetable();
		}
	}
	onMount(async () => {
		if (!timetableData) {
			timetableData = await fetchTimetableData(cellId);
		await redraw();
		}
	});
	$: loaded = false;
	$: unik = HASH + cellId + perspective + '-CCTT';

	let divsize;
	let wdivsize;
	let hdivsize;

	$: {
		wdivsize = containerWidth;
		hdivsize = (2 * wdivsize) / 3;
	}
</script>

<svelte:window
	bind:innerHeight={windowHeight}
	bind:innerWidth={windowWidth}
	on:_resize={throttle(redraw, 1000)}
	on:resize={redraw}
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
				<OutboundLink href="/fullScreen/timetable/{cellId}" icon={Carbon} target="_blank"
					><span style="font-size:x-small;">{cellId} </span></OutboundLink
				>
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
					style="overflow-y:auto;height:{dimensions[size].h}px;min-height:{dimensions[size]
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
		overflow-y: auto;
		overflow-x: visible;
		margin: 0px;
		padding: 0px;
	}
</style>
