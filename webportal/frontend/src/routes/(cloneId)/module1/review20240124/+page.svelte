<script>
	import { browser } from '$app/environment';
	import PedigreeTree from '@/lib/charts/components/PedigreeTree.svelte';
	import { loadingIndicatorToggle } from '@/lib/storage/local/stores';
	import {
		Button,
		TreeView
	} from 'carbon-components-svelte';
	import CloseOutline from 'carbon-icons-svelte/lib/CloseOutline.svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';
	import { Pane, Splitpanes } from 'svelte-splitpanes';

	let treeInstance;
	let rightPanelEnabled = false;
	let csize;
	csize = 'fit';
	$: rightPanelEnabled = rightSidePanelComponents.length > 0;

	/**
	 * @type {any[]}
	 */
	let rightSidePanelComponents = [];
	let maxRightSidePanelComponents = 16;

	async function addItemToBottomOfRightPanel(cmpnt, par) {
		const p = Object.fromEntries(Object.entries(par));
		let i = rightSidePanelComponents.length;
		if (i == maxRightSidePanelComponents) {
			rightSidePanelComponents.shift();
			rightSidePanelComponents = rightSidePanelComponents;
		}
		i = rightSidePanelComponents.length;
		const k = rightSidePanelComponents[i - 1]
			? rightSidePanelComponents[i - 1].id
				? rightSidePanelComponents[i - 1].id || 0
				: 0
			: 0;
		if (i < maxRightSidePanelComponents) {
			p.id = k + 1;
			rightSidePanelComponents.push({
				id: k + 1,
				c: cmpnt,
				p: p,
				f: removeRightSidePanelComponents
			});
		}
		rightSidePanelComponents = rightSidePanelComponents;
	}
	async function addItemToTopOfRightPanel(cmpnt, par) {
		const p = Object.fromEntries(Object.entries(par));
		let i = rightSidePanelComponents.length;
		if (i == 0) {
			p.id = 1;
			rightSidePanelComponents.push({ id: 1, c: cmpnt, p: p, f: removeRightSidePanelComponents });
			rightSidePanelComponents = rightSidePanelComponents;
			return;
		} else {
			if (i == maxRightSidePanelComponents) {
				rightSidePanelComponents.pop();
				i = rightSidePanelComponents.length;
			}
			let nrsp = rightSidePanelComponents.map((x) => {
				const par = Object.fromEntries(Object.entries(x.p));
				par.id++;
				return { id: x.id + 1, c: x.c, p: par, f: x.f };
			});
			p.id = 1;
			nrsp.unshift({
				id: 1,
				c: cmpnt,
				p: p,
				f: removeRightSidePanelComponents
			});
			rightSidePanelComponents = nrsp;
		}
	}
	/**
	 * @param {boolean} direction
	 * @param {any} c
	 * @param {any} p
	 */
	async function addItemToRightPanel(c, p) {
		const direction = true;
		return direction
			? await addItemToTopOfRightPanel(c, p)
			: await addItemToBottomOfRightPanel(c, p);
	}

	function removeRightSidePanelComponents(x) {
		const l = rightSidePanelComponents.length;
		let i = 0;
		for (i = 0; i < l; i++) {
			if (x == rightSidePanelComponents[i].id) break;
		}
		rightSidePanelComponents.splice(i, 1);
		rightSidePanelComponents = rightSidePanelComponents;
	}

	/**
	 * @param {any} c
	 * @param {any} p
	 */
	async function addComponent(c, p) {
		const UUID = performance.now();
		const C = p.cellId ? p.cellId : 'C';
		const P = p.perspective ? p.perspective : 'P';
		p.HASH = `${37 * Math.floor(UUID)}-${C}-${P}`;
		p.id = -1;
		p.size = csize;
		p.remove = removeRightSidePanelComponents;
		addItemToRightPanel(c, p);
	}

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

	function handleMessage(event) {
		if (event.detail && event.detail.length) {
			hscrollbox = windowHeight;
		}
	}

	function startLoading() {
		$loadingIndicatorToggle = true;
	}

	function stopLoading() {
		$loadingIndicatorToggle = false;
	}
	/**
	 * @param {string} item
	 */
	async function getDescendants(item) {
		if (!item) {
			return [];
		}

		startLoading();
		let formData = new FormData();
		formData.append('item', item);

		return await fetch('?/getdescendants', {
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
				console.log('CATCH', e);
			})
			.finally(() => {
				stopLoading();
			});
	}

	let hdivsize = 100;
	let wdivsize = 100;
	let hscrollbox = 100;
	let scrollbox;
	let scrollboxHeight = 0;
	let scrollboxWidth = 0;
	let scrollboxCallback = () => {};
	const bmargin = 80;

	const bgcl = 'white';
	const bght = '100%';
	const bgpd = '1px';
	const bgpt = '40px';

	const t1cl = 'green';
	const t1ht = '100%';
	const t1pd = '1px';
	const t1pt = '40px';

	function redraw() {
		hscrollbox = windowHeight;
		treeInstance?.resized();
	}

	onMount(() => {
		if (browser) {
			wdivsize = (windowWidth * 20) / 120.0;
			hdivsize = (2 * wdivsize) / 3;
			hscrollbox = windowHeight - bmargin;
		}
	});
	/**
	 * @type {TreeView | null}
	 */
	let treeview = null;
	$: searchtree = '';
	$: {
		wdivsize = (windowWidth * 20) / 120.0;
		hdivsize = (2 * wdivsize) / 3;
		hscrollbox = windowHeight - bmargin;
	}

	$: {
		wdivsize = scrollboxWidth - 20;
		hdivsize = (3 * wdivsize) / 4;
	}
</script>

<svelte:head>
	<title>Module 1</title>
</svelte:head>

<svelte:window
	bind:innerHeight={windowHeight}
	bind:innerWidth={windowWidth}
	on:_resize={throttle(redraw, 1000)}
	on:resize={redraw}
/>
<div style="background-color:{bgcl};height:{bght};padding:{bgpd};padding-top:{bgpt};">
	<Splitpanes
		theme="modern-theme"
		on:ready={handleMessage}
		on:resize={throttle(handleMessage, 1000)}
		on:resized={() => {
			treeInstance?.resized();
		}}
		on:pane-click={handleMessage}
		on:pane-maximize={handleMessage}
		on:pane-add={handleMessage}
		on:pane-remove={handleMessage}
		on:splitter-click={handleMessage}
	>
		<Pane minSize={60}>
				<div class="scrollbox" style="--hscrollbox:{hscrollbox};overflow:hidden;">
					<PedigreeTree
						bind:this={treeInstance}
						capabilities={{
							S: true,
							C: true,
							G: true,
							T: true,
							M: true,
							Mc2: true,
							Mt2: true,
							Mg2: true,
							Ls: true,
							Lc: true,
							Lg: true,
							Lt: true
						}}
						{addComponent}
					/>
				</div>
		</Pane>
		{#if rightSidePanelComponents && rightSidePanelComponents.length && rightPanelEnabled}
			<Pane size={35} maxSize={50} minSize={25}>
					<div class="hasborder">
						<Button
							size="small"
							kind="danger-ghost"
							tooltipPosition="right"
							tooltipAlignment="end"
							iconDescription="Restart"
							icon={CloseOutline}
							on:click={() => {
								rightSidePanelComponents = [];
								rightSidePanelComponents = rightSidePanelComponents;
							}}
						>
							<strong>Clear{rightSidePanelComponents && rightSidePanelComponents.length > 1 ? ' All' : ''}</strong>
						</Button>
					</div>
					<hr />
					<div
						class="scrollbox"
						style="--hscrollbox:{hscrollbox};"
						bind:this={scrollbox}
						bind:clientHeight={scrollboxHeight}
						bind:clientWidth={scrollboxWidth}
					>
						{#each rightSidePanelComponents as { id, c, p }, i (id)}
							{#key p.HASH}
								<div class="xyz" style="--wdivsize:{wdivsize};">
									<svelte:component this={c} {...p} />
									<br />
								</div>
							{/key}
						{/each}
					</div>
			</Pane>
		{/if}
	</Splitpanes>
</div>

<style global lang="scss">
	:global(.splitpanes.modern-theme) :global(.splitpanes__pane) {
		padding: 10px;
	}
	:global(.splitpanes.modern-theme) :global(.splitpanes__splitter) {
		background-color: #ccc;
		position: relative;
	}
	:global(.splitpanes.modern-theme) :global(.splitpanes__splitter:before) {
		content: '';
		position: absolute;
		left: 0;
		top: 0;
		transition: opacity 0.4s;
		background-color: #777;
		opacity: 0;
		z-index: 1;
	}
	:global(.splitpanes.modern-theme) :global(.splitpanes__splitter:hover) {
		cursor: col-resize;
	}
	:global(.splitpanes.modern-theme) :global(.splitpanes__splitter:hover:before) {
		opacity: 1;
	}

	:global(.modern-theme.splitpanes--vertical) > :global(.splitpanes__splitter:before) {
		left: -4px;
		right: -4px;
		height: 100%;
		cursor: col-resize;
	}
	:global(.modern-theme.splitpanes--horizontal) > :global(.splitpanes__splitter:before) {
		top: -3px;
		bottom: -3px;
		width: 100%;
		cursor: row-resize;
	}

	:global(.splitpanes.no-splitter) :global(.splitpanes__pane) {
		background-color: #00f8f8;
		padding: 10px;
	}
	:global(.splitpanes.no-splitter) :global(.splitpanes__splitter) {
		background-color: #ccc;
		position: relative;
	}

	:global(.no-splitter.splitpanes--horizontal) > :global(.splitpanes__splitter:before) {
		width: 0.225rem;
		pointer-events: none;
		cursor: none;
	}
	:global(.no-splitter.splitpanes--vertical) > :global(.splitpanes__splitter:before) {
		height: 2.225rem;
		pointer-events: none;
		cursor: none;
	}

	.xyz {
		width: calc(var(--wdivsize) * 1px);
		height: calc(var(--hdivsize) * 1px);
		border-style: solid;
		border-color: #000;
		border-width: 1px;
		margin: 0px;
		margin-bottom: 20px;
	}

	.scrollbox {
		display: flex;
		flex-direction: column;
		height: calc(var(--hscrollbox) * 1px);
		overflow-y: scroll;
		overflow-x: hidden;
		padding: 0px;
		margin: 10px;
		padding-bottom: 30px;
	}
	.hasborder {
		display: flex;
		flex-direction: row;
		align-items: center;
		border-style: solid;
		border-color: #000;
		padding: 8px;
		vertical-align: middle;
		color: rgb(0, 0, 0);
		font-size: 0.3rem;
	}
</style>
