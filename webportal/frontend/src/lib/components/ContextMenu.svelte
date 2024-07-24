<!-- 
<<<<<<< HEAD
Inspired from: Context Menu https://svelte.dev/repl/3a33725c3adb4f57b46b597f9dade0c1?version=3.25.0
-->
<script>
	let pos = { x: 0, y: 0 };
	let menu = { h: 0, y: 0 };
	let browser = { h: 0, y: 0 };
=======
Github @dukenmarga, July 2022
Context Menu is small menu that displayed when user right-click the mouse on browser.
Think of it as a way to show Refresh option on Microsoft Windows when right-click on desktop.
Known bug:
    - If the browser loads the content for the first time, showMenu set to false.
    Hence, we cannot get menu.h and menu.y dimension, since context menu has not been available at DOM.
    The first right click will not shown properly when right-click occurs around the edge (bottom part
    and right part) of the browser.

Inspired from: Context Menu https://svelte.dev/repl/3a33725c3adb4f57b46b597f9dade0c1?version=3.25.0
-->

<script>
	// pos is cursor position when right click occur
	let pos = { x: 0, y: 0 };
	// menu is dimension (height and width) of context menu
	let menu = { h: 0, y: 0 };
	// browser/window dimension (height and width)
	let browser = { h: 0, y: 0 };
	// showMenu is state of context-menu visibility
>>>>>>> master
	let showContextMenu = false;
	let showClickMenu = false;
	let showDblClickMenu = false;
	let showSettingsMenu = false;
<<<<<<< HEAD
=======
	// let showMenu = false;
	// to display some text
>>>>>>> master
	/**
	 * @type {{ textContent: string; }}
	 */
	let content;
	/**
	 * @type {string}
	 */
	let payload;
	let node;
<<<<<<< HEAD
	import { setClipBoard } from '$lib/js/clipboard';
	import {
		AddAlt,
		ChartBarFloating,
		ChartLine,
		ChartTSne,
		Copy,
		Information,
		Network_4Reference,
		Printer,
		Settings,
		TrashCan,
		ZoomArea
	} from 'carbon-icons-svelte';

=======
	import { setClipBoard } from '../js/clipboard';
	import { Slider } from 'carbon-components-svelte';
	import {
		AddAlt,
		Camera,
		ChartBarFloating,
		ChartLine,
		Copy,
		Information,
		InformationSquare,
		Network_4Reference,
		Printer,
		TrashCan,
		ZoomArea,
		Settings,
		ChartTSne
	} from 'carbon-icons-svelte';


>>>>>>> master
	export let callbackC = () => {};
	export let callbackM = (x) => {};
	export let callbackF = (x, y) => {};
	export let callbackJ = (x) => {};
	export let callbackO = (x) => {};

	let enabledViews = {};
	export function callMenu(x, y) {
		node = y ? y : null;
		payload = y ? (y.name ? y.name : '') : '';
		return rightClickContextMenu(x);
	}
	/**
	 * @param {{ type: any; clientX: any; clientY: any; } | null} e
	 */
	export function rightClickContextMenu(e) {
		if (e == null) {
			showContextMenu = false;
			showClickMenu = false;
			showDblClickMenu = false;
			showSettingsMenu = false;
			return -1;
		}
		switch (e.type) {
			case 'click':
				showSettingsMenu = false;
				showContextMenu = false;
				showDblClickMenu = false;
				showClickMenu = true;
				enabledViews = callbackJ(payload);
				enabledViews['copy'] = true;
				enabledViews['reroute'] = true;
				break;
		}
		browser = {
			w: window.innerWidth,
			h: window.innerHeight
		};
		pos = {
			x: e.clientX,
			y: e.clientY
		};
		if (browser.h - pos.y < menu.h) pos.y = pos.y - menu.h;
		if (browser.w - pos.x < menu.w) pos.x = pos.x - menu.w;
	}

	function getContextMenuDimension(node) {
		let height = node.offsetHeight;
		let width = node.offsetWidth;
		menu = {
			h: height,
			w: width
		};
	}
	function copyToClipboard() {
		setClipBoard(payload);
	}
	function setRoot() {
		callbackM(payload);
	}
	async function test_menu() {
		callbackF(payload, 'test_menu');
	}
	async function growthcurve() {
<<<<<<< HEAD
		callbackF(payload, 'pin_growth');
	}
	async function timetable() {
=======
		console.log('growthcurve', payload, callbackF);
		callbackF(payload, 'pin_growth');
	}
	async function timetable() {
		console.log('timetable', payload, callbackF);
>>>>>>> master
		callbackF(payload, 'pin_timetable');
	}
	async function genotype() {
		callbackF(payload, 'genotype');
	}
	async function genotype_genomeperspective() {
		callbackF(payload, 'genomeperspective');
	}
	async function genotype_transcriptomeperspective() {
		callbackF(payload, 'transcriptomeperspective');
	}
	async function genotype_karyotypeperspective() {
		callbackF(payload, 'karyotypeperspective');
	}
	async function genotype_exomeperspective() {
		callbackF(payload, 'exomeperspective');
	}
	async function genotype_morphologyperspective() {
		callbackF(payload, 'morphologyperspective');
	}
	function addItem() {
		content.textContent = 'Add and item...';
	}
	function print() {
		content.textContent = 'Printed...';
	}
	function zoom() {
		content.textContent = 'Zooom...';
	}
	function remove() {
		content.textContent = 'Removed...';
	}
	function setting() {
		content.textContent = 'Settings...';
	}
<<<<<<< HEAD
=======
	let dblClickItems = [
		{
			name: 'addItem',
			onClick: addItem,
			displayText: 'Add Item',
			class: 'fa-solid fa-plus'
		},
		{
			name: 'emptyicons',
			onClick: addItem,
			displayText: 'Empty Icon',
			class: 'fa-solid fa-square'
		},
		{
			name: 'zoom',
			onClick: zoom,
			displayText: 'Zoom',
			class: 'fa-solid fa-magnifying-glass'
		},
		{
			name: 'printMenu',
			onClick: print,
			displayText: 'Print',
			class: 'fa-solid fa-print'
		},
		{
			name: 'hr'
		},
		{
			name: 'settings',
			onClick: setting,
			displayText: 'Settings',
			class: 'fa-solid fa-gear'
		},
		{
			name: 'hr'
		},
		{
			name: 'trash',
			onClick: remove,
			displayText: 'Trash',
			class: 'fa-solid fa-trash-can'
		}
	];
>>>>>>> master
	let availableClickItems = [
		'copy',
		'curve',
		'timetable',
		'genomeperspective',
		'transcriptomeperspective',
		'karyotypeperspective',
		'exomeperspective',
		'morphologyperspective'
	];
	let clickItems = [
		{
			name: 'curve',
			onClick: growthcurve,
			displayText: '︎Growth curve',
			class: 'fa-solid fa-chart-line',
			icon: ChartLine
		},
		{
			name: 'curve',
			element: 'hr'
		},
		{
			name: 'timetable',
			onClick: timetable,
			displayText: '︎Time table',
			class: 'fa-solid fa-chart-gantt',
			icon: ChartBarFloating
		},
		{
			name: 'timetable',
			element: 'hr'
		},
		{
			name: 'genomeperspective',
			onClick: genotype_genomeperspective,
			displayText: '︎Genome Persp.',
			class: 'fa-solid fa-camera',
			icon: ChartTSne
		},
		{
			name: 'transcriptomeperspective',
			onClick: genotype_transcriptomeperspective,
			displayText: 'Transcriptome Persp.',
			class: 'fa-solid fa-camera',
			icon: ChartTSne
		},
		{
			name: 'karyotypeperspective',
			onClick: genotype_karyotypeperspective,
			displayText: 'Karyotype Persp.',
			class: 'fa-solid fa-camera',
			icon: ChartTSne
		},
		{
			name: 'exomeperspective',
			onClick: genotype_exomeperspective,
			displayText: 'Exome Persp.',
			class: 'fa-solid fa-camera',
			icon: ChartTSne
		},
		{
			name: 'morphologyperspective',
			onClick: genotype_morphologyperspective,
			displayText: 'Morphology Persp.',
			class: 'fa-solid fa-camera',
			icon: ChartTSne
		},
		{
			name: 'nodeinfo',
			onClick: addItem,
			displayText: 'Node info',
			class: 'fa-solid fa-camera',
			icon: Information
		},
		{
			name: 'addItem',
			onClick: addItem,
			displayText: 'Add Item',
			class: 'fa-solid fa-plus',
			icon: AddAlt
		},
		{
			name: 'zoom',
			onClick: zoom,
			displayText: 'Zoom',
			class: 'fa-solid fa-magnifying-glass',
			icon: ZoomArea
		},
		{
			name: 'printMenu',
			onClick: print,
			displayText: 'Print',
			class: 'fa-solid fa-print',
			icon: Printer
		},
		{
			element: 'hr'
		},
		{
<<<<<<< HEAD
=======
			name: 'settings',
			onClick: async () => {
				await new Promise((res) => setTimeout(res, 300)).then(async () => {
					showDblClickMenu = false;
					showClickMenu = false;
					await new Promise((res) => setTimeout(res, 300)).then(() => {
						showContextMenu = true;
					});
				});
			},
			displayText: 'Settings',
			class: 'fa-solid fa-gear',
			icon: Settings
		},
		{
			element: 'hr'
		},
		{
			name: 'trash',
			onClick: remove,
			displayText: 'Trash',
			class: 'fa-solid fa-trash-can',
			icon: TrashCan
		},
		{
>>>>>>> master
			name: 'copy',
			element: 'hr'
		},
		{
			name: 'copy',
			onClick: copyToClipboard,
			displayText: 'Copy ',
			class: 'fa-solid fa-plus',
			icon: Copy
		},
		{
<<<<<<< HEAD
=======
			name: 'reroute',
			element: 'hr'
		},
		{
			name: 'reroute',
			onClick: setRoot,
			displayText: 'set as root',
			class: 'fa-solid fa-diagram-project',
			icon: Network_4Reference
		},
		{
>>>>>>> master
			name: 'test',
			onClick: test_menu,
			displayText: '︎Test Menu',
			class: 'fa-solid fa-chart-line',
			icon: ChartLine
		}
	];
<<<<<<< HEAD

=======
	let contextmenuItems = [
		{
			name: 'addItem',
			onClick: copyToClipboard,
			displayText: 'Copy',
			class: 'fa-solid fa-plus',
			icon: Copy
		},
		{
			name: 'emptyicons',
			onClick: setRoot,
			displayText: 'Set root',
			class: 'fa-solid fa-diagram-project',
			icon: Network_4Reference
		},
		{
			name: 'nodeinfo',
			onClick: addItem,
			displayText: 'Node info',
			class: 'fa-solid fa-camera',
			icon: Information
		},
		{
			name: 'nodeinfo',
			name: 'hr'
		},
		{
			name: 'settings',
			onClick: async () => {
				await new Promise((res) => setTimeout(res, 300)).then(() => {
					showDblClickMenu = false;
					showContextMenu = false;
					showSettingsMenu = true;
				});
			},
			displayText: 'Settings',
			class: 'fa-solid fa-gear',
			icon: Settings
		}
	];
	let settingsmenuItems = [
		{
			name: 'zoom',
			onClick: zoom,
			displayText: 'Zoom',
			class: 'fa-solid fa-magnifying-glass',
			icon: ZoomArea
		},
		{
			name: 'hr'
		},
		{
			name: 'settings',
			onClick: async () => {
				await new Promise((res) => setTimeout(res, 300)).then(() => {
					showDblClickMenu = false;
					showContextMenu = false;
					showClickMenu = true;
				});
			},
			displayText: 'Settings',
			class: 'fa-solid fa-gear',
			icon: Settings
		}
	];
	/**
	 * @type {Button}
	 */
	let buttonrow;
>>>>>>> master
</script>

{#if showClickMenu}
	<nav use:getContextMenuDimension style="position: absolute; top:{pos.y}px; left:{pos.x}px">
		<div class="navbar" id="navbar">
			<ul>
				{#each clickItems as item}
					{#if true && item.name && availableClickItems.includes(item.name)}
						{#if item.element == 'hr'}
							<hr />
						{:else}
							<li>
								{#if enabledViews[item.name]}
									<button on:click={item.onClick} style="margin:0px;padding:0px;height:24px">
										<div class="clickmenu">
											<svelte:component
												this={item.icon}
												style="text-align:right;height:16px;margin-right:8px;padding:0px;"
											/>
											<span style="font-size:0.8rem;padding-bottom:14px;">
												{#if item.name == 'copy'}
													{item.displayText}
													<span style="font-weight:500;font-size:0.5rem;width:100%;">'{payload.toString()}'</span>
												{:else}
													{item.displayText}
												{/if}
											</span>
										</div>
									</button>
								{:else}
									<button on:click={() => {}} style="margin:0px;padding:0px;height:24px">
										<div class="clickmenudisabled">
											<svelte:component
												this={item.icon}
												style="text-align:right;height:16px;margin-right:8px;padding:0px;"
											/>
											<span style="font-size:0.8rem;padding-bottom:14px;">
												{item.displayText}
											</span>
										</div>
									</button>
								{/if}
							</li>
						{/if}
					{/if}
				{/each}
			</ul>
		</div>
	</nav>
{/if}

<<<<<<< HEAD

=======
{#if false && showContextMenu}
	<nav use:getContextMenuDimension style="position: absolute; top:{pos.y}px; left:{pos.x}px">
		<div class="navbar" id="navbar">
			<ul>
				{#each contextmenuItems as item}
					{#if item.name == 'hr'}
						<hr />
					{:else}
						<li>
							<button on:click={item.onClick} style="margin:0px;padding:0px;height:24px">
								<div class="clickmenu">
									<svelte:component
										this={item.icon}
										style="text-align:right;height:16px;margin-right:8px;padding:0px;"
									/>
									<span style="font-size:0.8rem;padding-bottom:14px;">
										{item.displayText}
									</span>
								</div>
							</button>
						</li>
					{/if}
				{/each}
			</ul>
		</div>
	</nav>
{/if}

{#if false && showSettingsMenu}
	<nav use:getContextMenuDimension style="position: absolute; top:{pos.y}px; left:{pos.x}px">
		<div class="navbar" id="navbar">
			<ul>
				{#each settingsmenuItems as item}
					{#if item.name == 'hr'}
						<hr />
					{:else if item.name == 'zoom'}
						<Slider hideLabel light style="margin:0px;padding:0px;width:150px" />
					{:else}
						<li>
							<button on:click={item.onClick} style="margin:0px;padding:0px;height:24px">
								<div class="clickmenu">
									<svelte:component
										this={item.icon}
										style="text-align:right;height:16px;margin-right:8px;padding:0px;"
									/>
									<span style="font-size:0.8rem;padding-bottom:14px;">
										{item.displayText}
									</span>
								</div>
							</button>
						</li>
					{/if}
				{/each}
			</ul>
		</div>
	</nav>
{/if}

{#if false && showDblClickMenu}
	<nav use:getContextMenuDimension style="position: absolute; top:{pos.y}px; left:{pos.x}px">
		<div class="navbar" id="navbar">
			<ul>
				{#each dblClickItems as item}
					{#if item.name == 'hr'}
						<hr />
					{:else}
						<li>
							<button on:click={item.onClick}
								>||<i class={item.class}></i>||{item.displayText}</button
							>
						</li>
					{/if}
				{/each}
			</ul>
		</div>
	</nav>
{/if}
>>>>>>> master
<style>
	* {
		padding: 0;
		margin: 0;
		z-index: 900;
	}
	.navbar {
		display: inline-flex;
		border: 2px #777e solid;
		width: 200px;
		background-color: #fff;
		background-color: rgb(248, 248, 248);
		border-radius: 0px;
		overflow: hidden;
		flex-direction: column;
		z-index: 900;
	}
	.navbar ul {
		margin: 0px;
	}
	ul li {
		display: block;
		list-style-type: none;
		width: 1fr;
	}
	ul li button {
		font-size: 1rem;
		color: #222;
		width: 100%;
		height: 30px;
		text-align: left;
		border: 0px;
		background-color: #fff;
	}
	ul li Button:hover {
		color: #fff;
		text-align: left;
		border-radius: 0px;
		background-color: blue;
	}
	.clickmenudisabled {
		font-size: 1rem;
		color: rgba(128, 128, 128, 0.5);
		text-align: left;
		vertical-align: center;
		border-radius: 0px;
		background-color: rgb(248, 248, 248);
		width: 100%;
		height: 24px;
		padding: 5px;
		display: inline-flex;
		border-radius: 0px;
		overflow: hidden;
		flex-direction: row;
		cursor: not-allowed;
	}
	.clickmenudisabled:hover {
		border-radius: 0px;
	}
	.clickmenu {
		font-size: 1rem;
		color: black;
		text-align: left;
		vertical-align: center;
		border-radius: 0px;
		background-color: rgb(248, 248, 248);
		width: 100%;
		height: 24px;
		padding: 5px;
		display: inline-flex;
		border-bottom: 0px #099 solid;
		border-radius: 0px;
		overflow: hidden;
		flex-direction: row;
		cursor: pointer;
	}
	.clickmenu:hover {
		color: #fff;
		width: 100%;
		text-align: left;
		border-radius: 1px;
		background-color: blue;
	}
	ul li button i {
		padding: 0px 15px 0px 10px;
	}
	ul li button i.fa-square {
		color: #fff;
	}
	ul li button:hover > i.fa-square {
		color: #eee;
	}
	ul li button:hover > i.warning {
		color: crimson;
	}
	:global(ul li button.info:hover) {
		color: navy;
	}
	hr {
		border: none;
		border-bottom: 1px solid #ccc;
		margin: 3px 0px;
	}
</style>
