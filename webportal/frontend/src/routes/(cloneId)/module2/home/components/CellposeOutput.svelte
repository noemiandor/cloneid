<script>
	import { GlobPVARS, phenotypeShowOverlayImages } from '@/lib/storage/local/stores';
	import { Button, Column, DataTable, Grid, Row, Tile, Toggle } from 'carbon-components-svelte';
	import { onMount } from 'svelte';
	import { scale } from 'svelte/transition';
	/**
	 * @type {any[]}
	 */
	// export
	let phenotypeImgOverlayData = [];
	/**
	 * @type {any[]}
	 */
	// export
	let phenotypeImgOverlay = [];
	/**
	 * @type {any[] | Promise<any>}
	 */
	// export
	let finalResults = [];
	// /**
	//  * @type {string:any}
	//  */
	export let seginfo = {};

	function decoderesponse(x) {
		const kv = JSON.parse(x.data);
		const k = kv[0];
		let d = {};
		for (let [k1, v1] of Object.entries(k)) {
			d[k1] = kv[v1];
		}
		return d;
	}

	async function loadResults() {

		console.log('CellPose loadresult processphenotyperesults', seginfo);
		if (!seginfo.s) return;
		const formData3 = new FormData();

		formData3.append('h', seginfo.h);
		formData3.append('s', seginfo.s);
		formData3.append('t', seginfo.t);

		await fetch('?/processphenotyperesults', { method: 'POST', body: formData3 })
			.then(async (res) => {
				const x = await res.json();
				let d = {};
				if (x.status === 200) {
					d = decoderesponse(x);
					const ls = await JSON.parse(d.ls);
					d.ls = ls;
					phenotypeImgOverlay = ls.map((x) => {
						x.reload = 0;
						x.checked = true;
						x.imgname = x.name;
						return x;
					});
					console.log('phenotypeImgOverlay', phenotypeImgOverlay);
					phenotypeImgOverlayData = ls.map((x) => {
						x.reload = 0;
						x.checked = true;
						x.imgname = x.name;
						return x;
					});
					console.log('phenotypeImgOverlayData', phenotypeImgOverlayData);
				} else {
					throw x;
				}
			})
			.catch((e) => {
				console.log('processphenotype', e);
			});
	}

	let disableImport2CloneidButton = false;
	let rows = [
		{
			id: 0,
			images: 0,
			cellcount: 0,
			areaoccupiedum2: 0,
			cellsizeum2: 0
		}
	];
	let commitpassageingButtonAlreadyClicked = false;
	function logResults() {
		console.log($phenotypeShowOverlayImages);
		console.log(seginfo);
		console.log(finalResults);
		console.log(phenotypeImgOverlay);
		console.log(phenotypeImgOverlayData);
	}
	onMount(async () => {
		await loadResults();
		logResults();
		if (seginfo.results) {
			rows[0].id = 0;
			rows[0].cellcount = seginfo.results.cellCount;
			rows[0].areaoccupiedum2 = seginfo.results.areaOccupied_um2;
			rows[0].cellsizeum2 = seginfo.results.cellSize_um2;
		}
	});
</script>

<Button
	on:click={(x) => {
		logResults();
	}}
/>
{#if $phenotypeShowOverlayImages}
	<Tile>
		<h4>
			{@html ['Segmentation Results', seginfo.imageid, seginfo.event].join('&nbsp;&mdash;&nbsp;')}
		</h4>
	</Tile>
	<Grid fullWidth style="padding:10px;padding-top:0px;">
		{#key finalResults}
			{#each [0, 1] as xy}
				<Row
					style="
					margin:0px;
					ipadding:0px;
					ibackground-color:rgb(200,200,200);
					outline-style:solid; outline-color:#FF0000FF; outline-width:0px;
					border-style:solid; border-color:#0000FFFF; border-width:0px; 
					_display: flex; flex-direction: row; align-items: center;
					iheight:40vh;
					"
				>
					{#each [2 * xy, 2 * xy + 1] as index}
						<Column
							sm={1}
							md={4}
							lg={8}
							style="
							padding:10px;
							iheight:40vh;
							idisplay: flex; flex-direction: column; align-items: center;
							text-align:center;
							"
						>
							{#if phenotypeImgOverlay[index] && phenotypeImgOverlay[index].imgsuffix != 'sssssl'}
								{#key phenotypeImgOverlay[index].reload}
									<div style="height:100%;xwidth:400px;text-align:center;padding:5px;">
										<img
											src={phenotypeImgOverlayData[index].imgsrc}
											style="object-fit: contain;
														max-width: 80%;
														max-height: 80%;
														outline-style:solid; outline-color:#000000FF; outline-width:2px;
														{phenotypeImgOverlay[index].checked ? '' : 'opacity:0.01;'}
														"
											alt={phenotypeImgOverlay[index].short}
										/>
									</div>

									{phenotypeImgOverlay[index].prefix}
									{#if $GlobPVARS && $GlobPVARS.length && $GlobPVARS['excludeOption'][0] && $GlobPVARS['toExclude'] && $GlobPVARS['toExclude'].includes(phenotypeImgOverlay[index].suffix)}
										<strong><span style="color:red;">[Excluded]</span></strong>
									{/if}
								{/key}
							{/if}
						</Column>
					{/each}
				</Row>
			{/each}
		{/key}
	</Grid>
	<Tile>
		{#key finalResults}
			<DataTable
				headers={[
					{ key: 'cellcount', value: 'cellcount' },
					{ key: 'areaoccupiedum2', value: 'areaOccupied_um2' },
					{ key: 'cellsizeum2', value: 'cellSize_um2' },
					{ key: 'submit', value: '' }
				]}
				{rows}
			>
				<svelte:fragment slot="cell-header" let:header>
					<div style="text-align:center;">
						{header.value}
					</div>
				</svelte:fragment>
				<svelte:fragment slot="cell" let:row let:cell>
					<div transition:scale style="text-align:center;">
							{Math.floor(cell.value)}
					</div>
				</svelte:fragment>
			</DataTable>
		{/key}
		<Grid>
			{#if false}
				{#each finalResults as z, i}
					<Row>
						<Column sm={1} md={1} lg={1}>
							{i}
						</Column>
						<Column sm={1} md={2} lg={2}>
							{z.k}
						</Column>
						<Column sm={1} md={1} lg={1}></Column>
						<Column sm={2} md={3} lg={3}>
							{z.v}
						</Column>
						<Column sm={1} md={3} lg={5}>
							{#if z.k === 'sqlinsert'}
								<Button
									expressive
									on:click|once={(x) => {
										commitpassaging(z.v);
									}}>Commit to passaging table</Button
								>
							{/if}
						</Column>
					</Row>
					<hr />
				{/each}
				<br />
			{/if}
		
		</Grid>
	</Tile>
{/if}
