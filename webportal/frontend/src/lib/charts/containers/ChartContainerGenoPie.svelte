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
	import { Button, OutboundLink, Tile, TooltipIcon } from 'carbon-components-svelte';
	import { CloseOutline } from 'carbon-icons-svelte';
	import * as d3 from 'd3';
	import throttle from 'just-throttle';
	import { fetchGenotypePieData } from '../../fetchdata/fetch';

	/**
	 * @param {any[]} data
	 * @param {number} width
	 * @param {number} height
	 */
	function d3ChartGenotypePie(data, width, height) {
		const color = d3
			.scaleOrdinal()
			.domain(data.map((d) => d.name))
			.range(d3.quantize((t) => d3.interpolateSpectral(t * 0.8 + 0.1), data.length).reverse());

		const pie = d3
			.pie()
			.sort((a, b) => b.value - a.value)
			.value((d) => d.value);

		const arc = d3
			.arc()
			.innerRadius(0)
			.outerRadius(Math.min(width, height) / 3 - 1);

		const labelRadius = arc.outerRadius()() * 0.8;

		const arcLabel = d3.arc().innerRadius(labelRadius).outerRadius(labelRadius);

		const arcs = pie(data);

		const svg = d3
			.create('svg')
			.attr('width', width)
			.attr('height', height)
			.attr('viewBox', [-width / 8 + -width / 2, -height / 2, width, height])
			.attr('style', 'max-width: 100%; height: 100%; font: 17px sans-serif;');

		svg
			.append('g')
			.attr('stroke', 'white')
			.selectAll()
			.data(arcs)
			.join('path')
			.attr('fill', (d) => color(d.data.name))
			.attr('stroke', function (d) {
				return '#eee';
			})
			.attr('stroke-width', function (d) {
				return '1';
			})
			.attr('d', arc)
			.append('title')
			.text((d) => `${d.data.name}: ${d.data.value.toLocaleString('en-US')}`);

		svg
			.append('g')
			.attr('text-anchor', 'middle')
			.selectAll()
			.data(arcs)
			.join('text')
			.attr('transform', (d) => `translate(${arcLabel.centroid(d)})`)
			.call((text) =>
				text
					.filter((d) => d.endAngle - d.startAngle > 0.25)
					.append('tspan')
					.attr('x', 0)
					.attr('fill-opacity', 1)
					.attr('font-weight', 'bold')
					.attr('font-size', '10')
					.attr('fill', function (d) {
						return '#000';
					})
					.text((d) => d.data.value.toLocaleString('en-US'))
			);

		var slices = pie(data);

		svg
			.append('g')
			.attr('transform', `translate(${-45 + -width / 2},${-height / 2})`)
			.attr('class', 'legend')
			.selectAll('text')
			.data(slices)
			.enter()
			.append('text')
			.text(function (d) {
				return '◼︎ ';
			})
			.attr('fill', function (d) {
				return color(d.data.value);
			})
			.attr('font-size', function (d) {
				return '24';
			})
			.attr('stroke', function (d) {
				return 'gray';
			})
			.attr('stroke-width', function (d) {
				return '0.9';
			})
			.attr('font-weight', 'bold')
			.attr('y', function (d, i) {
				return 20 * (i + 1);
			});

		if (true)
			svg
				.append('g')
				.attr('transform', `translate(${-25 + -width / 2},${-5 + -height / 2})`)
				.attr('class', 'legend')
				.selectAll('text')
				.data(slices)
				.enter()
				.append('text')
				.text(function (d) {
					return d.data.name;
				})
				.attr('fill', function (d) {
					return '#111';
				})
				.attr('font-size', function (d) {
					return '9';
				})
				.attr('font-weight', 'bold')
				.attr('y', function (d, i) {
					return 20 * (i + 1);
				});

		return svg.node();
	}

	async function drawPieCellCount() {
		const data = await fetchGenotypePieData(cellId, perspective)
			.then((x) => {
				return x.data;
			})
			.catch((e) => {
				console.log('259 CHARTCONTAINERPIE::CHARTGENOTYPEPIE::ERROR', cellId, perspective, e);
				throw e;
			});

		const H =
			dimensions[size].h == -1
				? containerHeight == 0
					? windowHeight - 90
					: containerHeight
				: dimensions[size].h;
		const W = containerWidth;

		const el = d3ChartGenotypePie(data, W, H);
		ContainerDomId?.firstChild?.remove();
		ContainerDomId?.append(el);

		if (typeof completion === 'function') {
			completion(true);
		}
	}
	async function redraw() {
		if (browser && cellId && perspective) {
			ContainerDomId?.firstChild?.remove();
			await drawPieCellCount();
		}
	}
	let cOrL = '';
	$: {
		cOrL = unik;
		if (cOrL) {
			redraw();
		}
	}
	$: unik = HASH + cellId + perspective + 'GP';
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
			on:click={(e) => {
				e.preventDefault();
			}}
		>
			<span style="font-size:xx-small;">{cellId} {perspective}</span>
		</Button>

		<Button
			style="margin:0px;padding:0px;"
			size="small"
			kind="ghost"
			tooltipPosition="left"
			tooltipAlignment="end"
			iconDescription="Open in new Window"
			><TooltipIcon tooltipText="Open in new Window">
				<OutboundLink href="/fullScreen/genotypePie/{cellId}&{perspective}" />
			</TooltipIcon>
		</Button>
	{/if}
	{#if size == 'fitwidth' || size == 'fullscreen' || size == 'max'}
		<div bind:clientWidth={containerWidth} bind:clientHeight={containerHeight}>
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
		</div>
	{:else}
		<div bind:clientWidth={containerWidth} bind:clientHeight={containerHeight}>
			<div bind:this={ContainerDomId} role="img"></div>
		</div>
	{/if}
</Tile>
