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

	// let busy = false;

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
		ButtonSet,
		ImageLoader,
		InlineLoading,
		OutboundLink,
		Tile,
		TooltipIcon,
		truncate
	} from 'carbon-components-svelte';
	import { CloseOutline } from 'carbon-icons-svelte';
	import throttle from 'just-throttle';
	import { fetchGenotypeUMAPData } from '../../js/fetchdata/fetch';
	import { onMount } from 'svelte';

	let heatmapimg = null;

	let jsonData = null;

	let w1;
	let h1;
	let w2;
	let h2;

	/**
	 * @param {string} query
	 */
	async function drawUMAP() {
		if (jsonData) {
			const json = jsonData;
			if ('data' in json) {
				const data = json.data;

				const H = h1;
				const W = w1;

				let el;

				if (data && data.type === 'heatmap') {
					ContainerDomId?.firstChild?.remove();
					el = document.createElement('img');
					el.src = data.imgdata64;
					el.width = (H * 1280) / 960;
					el.height = H;
					ContainerDomId?.append(el);
				} else {
					el = Plot.plot({
						height: H,
						width: W,
						grid: true,
						inset: 30,
						aspectRatio: 1,
						color: { legend: true },
						marks: [
							Plot.dot(data, {
								x: 'x',
								y: 'y',
								fill: perspective == 'MorphologyPerspective' ? 'none' : 'color',
								stroke: perspective == 'MorphologyPerspective' ? 'black' : 'color',
								tip: 'y',
								channels: { subclone: 'subclone', x: '' }
							}),
							Plot.crosshair(data, { x: 'x', y: 'y' }),
							Plot.dot(
								data,
								Plot.pointer({
									x: 'culmen_length_mm',
									y: 'culmen_depth_mm',
									fill: 'red',
									r: 8
								})
							)
						]
					});
					ContainerDomId?.firstChild?.remove();
					ContainerDomId?.append(el);
				}
				loaded = true;
				if (typeof completion === 'function') {
					completion(true);
				}
			} else {
				throw json;
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
			await new Promise((r) => setTimeout(r, 1500));
				await drawUMAP();
			waitingforredraw = false;
		}
		th();
	}

	async function asyncredraw() {
		await redraw();
	}
	onMount(async () => {
		jsonData = await fetchGenotypeUMAPData(cellId, perspective);
		await redraw();
	});

	$: loaded = false;
	$: unik = HASH + cellId + perspective + '-CCGXU';

	let divsize;
	let wdivsize;
	let hdivsize;

	$: {
		wdivsize = containerWidth ;
		hdivsize = (2 * wdivsize) / 3;

			const th = async () => {
				await drawUMAP();
				w1 = wdivsize;
				h1 = hdivsize;
			};
			th();
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
	ustyle="margin:0px;padding:0px;border: 0rem outset black;
outline: 0.05rem solid #7772;
border-radius: 0px;
font: bold 0.1rem sans-serif;
outline-offset: 0.05rem;_text-align:right;margin-bottom:-18px;"
>
<div style="background-color:white;">
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
			style="margin:0px;padding:0px;"
			size="small"
			kind="ghost"
			type="submit"
			on:click={(e) => {
			}}
		>
			<TooltipIcon tooltipText="Open in new Window">
				<OutboundLink href="/fullScreen/genotypeInfo/{cellId}&{perspective}">
					{#if wdivsize > 300}
						<span style="font-size:xx-small;">{cellId} {perspective}</span>
					{:else}
						<span style="font-size:0.3rem;">{cellId}<br />{perspective}</span>
					{/if}
				</OutboundLink>
			</TooltipIcon>
		</Button>
	{/if}
	{#if !loaded}
		<InlineLoading status="active" description="Loading data..." />
	{/if}

	<div bind:clientWidth={containerWidth} bind:clientHeight={containerHeight}>
		{#key unik}
			{#if heatmapimg}
				<!-- <Tile> -->
				<div
					bind:this={ContainerDomId}
					class="xyz1"
					style="--wdivsize:{wdivsize};--hdivsize:{hdivsize};text-align:center;background-color:white;"
				>
				</div>
			{:else if size == 'modal'}
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
			{:else if size == 'fit'}
				<div
					bind:this={ContainerDomId}
					class="xyz1"
					style="--wdivsize:{wdivsize};--hdivsize:{hdivsize};"
				></div>
			{:else if size == 'fito' || size == 'fitwidth' || size == 'fullscreen' || size == 'max'}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="
				overflow-y:auto;
				min-height:{dimensions['xs'].h};
				min-width:{dimensions['xs'].w};
				height:{dimensions[size].domh};
				width:{dimensions[size].domw};
				"
				></div>
			{:else}
				<div
					bind:this={ContainerDomId}
					role="img"
					style="overflow-y:auto;height:{dimensions[size].h}px;min-height:{dimensions[size]
						.h}px;min-width:{dimensions[size].w}px;"
				></div>
			{/if}
		{/key}
	</div>
</div>

</Tile>

<style>
	.xyz1 {
		width: calc(var(--wdivsize) * 1px);
		height: calc(var(--hdivsize) * 1px);
		border-width: 0px;
		margin: 0px;
		padding: 0px;
	}
</style>
