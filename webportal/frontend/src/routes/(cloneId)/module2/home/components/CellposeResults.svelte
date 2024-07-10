<script>
	import InputRequestWebWorker from '@/lib/components/ww/irww/InputRequestWebWorker.svelte';
	import { fetchUrl } from '@/lib/fetchdata/fetchUrl';
	import { getUserHash } from '@/lib/mysql/getuserhash';
	import { GlobPVARS, loadingIndicatorToggle, phenotypeShowOverlayImages } from '@/lib/storage/local/stores';
	import { Button, Column, DataTable, Grid, Modal, Row, Tab, TabContent, Tabs, Tile } from 'carbon-components-svelte';
	import { scale } from 'svelte/transition';
	import Download from './Download.svelte';

	/**
	 * @type {string}
	 */
	export let id;

	export let picsonly = false;

	/**
	 * @type {string[]}
	 */
	export let exclude;

	/**
	 * @type {string}
	 */
	let processedl;
	/**
	 * @type {any}
	 */
	let processedd;
	/**
	 * @type {any}
	 */
	let processedi;

	/**
	 * @type {{ timestamp: { toString: () => string | Blob; }; userhash: { toString: () => string | Blob; }; s: { toString: () => string | Blob; }; imageid: { toString: () => string | Blob; }; from: { toString: () => string | Blob; }; media: { toString: () => string | Blob; }; flask: { toString: () => string | Blob; }; cellcount: { toString: () => string | Blob; }; event: { toString: () => string | Blob; }; dishsurfacearea: { toString: () => string | Blob; }; flaskitems: { toString: () => string | Blob; }; mediaitems: { toString: () => string | Blob; }; waitforresult: { toString: () => string | Blob; }; results: { cellCount: number; areaOccupied_um2: number; cellSize_um2: number; }; }}
	 */
	let seginfo;

	async function import2cloneid() {


		getUserHash();
		seginfo['x'] = 'i';
		const j = await fetchUrl('/api/seginfo', 'post', seginfo)
			.then(async (res) => {
				const x = await res.json();
				if (res.status === 200) {
					const d = x.data;
					return d.i;
				}
			})
			.catch((e) => {
				throw e;
			});

		txid = j;
		return j;
	}

	/**
	 * @param {string} s
	 */
	async function loadSeginfo(s) {
		getUserHash();
		const p = {
			x: picsonly ? 'imgs' : 'r',
			s: s,
			z: 0
		};

		const j = await fetchUrl('/api/seginfo', 'post', p)
			.then(async (res) => {
				if (res.status === 200) {
					const x = await res.json();
					const r = x.data.r;
					if (picsonly) {
						processedi = JSON.parse(r.imgs);
					} else {
						processedl = r.date;
						if (r.imgs == {}) {
							return;
						}
						processedd = JSON.parse(r.data);
						processedi = JSON.parse(r.imgs);
						seginfo = processedd.seginfo;
						if (seginfo.results) {
							rows[0].id = 0;
							rows[0].cellcount = seginfo.results.cellCount;
							rows[0].areaoccupiedum2 = seginfo.results.areaOccupied_um2;
							rows[0].cellsizeum2 = seginfo.results.cellSize_um2;
						}
					}
				} else {
					throw res;
				}
			})
			.catch(async (e) => {
				throw e;
			});
		$loadingIndicatorToggle = false;
		if (!picsonly) {
			exclude = processedd['toExclude'];
		}
		return j;
	}
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
		console.log('processedl', processedl);
		console.log('processedd', processedd.seginfo);
		console.log('processedi', processedi);
	}
	let disableImport2CloneidButton = false;
	/**
	 * @type {undefined}
	 */
	let txid;
	let tick;
	let notifk1 = '';
	let notifk2 = '';
	let notifk3 = '';
	let notifk4 = '';
	let askforinputProps = {
		show: !true,
		prompt: 'Select:',
		retry: 'Invalid option',
		options: ['A', 'B', 'C'],
		infomessage: '',
		infotype: '',
		txid: 0
	};
	$: notif = {};
	/**
	 * @type {string[]}
	 */
	let i2cmessages = [
	];
	let openI2cmessage = false;
	let details_i2cmessages = false;
	$: selectedTab = 1;

	let RDD = 0;
	let SFS = 0;
</script>


{#await loadSeginfo(id)}
	<Tile>Loading results...</Tile>
{:then info}
	<Tile>
		<Grid fullWidth>
			{#if !picsonly}
				<Row>
					<Column>
						<Tile light>
							<h4>
								{@html [
									'Segmentation Results',
									processedd.seginfo.imageid,
									processedd.seginfo.event
								].join('&nbsp;&mdash;&nbsp;')}
							</h4>
						</Tile>
					</Column>
				</Row>
			{/if}
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
						{#if processedi[index]}
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
								<div style="height:100%;xwidth:400px;text-align:center;padding:5px;">
									<img
										src={processedi[index].imgsrc}
										style="object-fit: contain;
														max-width: 80%;
														max-height: 80%;
														outline-style:solid; outline-color:#000000FF; outline-width:2px;
														{processedi[index] && exclude && exclude.includes(processedi[index].suffix)
											? 'opacity:0.50;'
											: 'opacity:1.00;'}
														"
										alt={processedi[index].short}
									/>
								</div>

								{processedi[index].prefix}
								{#if processedi[index] && exclude && exclude.includes(processedi[index].suffix)}
									<strong><span style="color:red;">[Excluded]</span></strong>
								{/if}
							</Column>
						{/if}
					{/each}
				</Row>
			{/each}
		</Grid>
	</Tile>

	{#if !picsonly}
		<Tile>
			<h5>Results Summary</h5>
			<DataTable
				headers={[
					{ key: 'cellcount', value: 'cellcount' },
					{ key: 'areaoccupiedum2', value: 'areaOccupied_um2' },
					{ key: 'cellsizeum2', value: 'cellSize_um2' }
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
						{#if cell.key === 'submit'}
							<Button
								disabled={commitpassageingButtonAlreadyClicked}
								on:click|once={async (x) => {
									commitpassageingButtonAlreadyClicked = true;
								}}
							>
								Submit
							</Button>
						{:else}
							{Math.floor(cell.value)}
						{/if}
					</div>
				</svelte:fragment>
			</DataTable>
			<Tile light>
				<Grid fullWidth>
					<Row>
						<Column sm={1} md={4} lg={8} style="text-align:center;">
							<Download
								id={processedd.seginfo.s.toString()}
								filename={processedd.seginfo.imageid.toString()}
							/>
						</Column>
						<Column sm={1} md={4} lg={8} style="text-align:center;">
							{#key i2cmessages}
								{#if false && i2cmessages.length}
									<Tile style="text-align:left;">
										<ul>
											{#each i2cmessages as i2cmessage}
												<li>
													{i2cmessage}
												</li>
											{/each}
										</ul>
									</Tile>
								{:else}
									<Button
										on:click={async (x) => {
											$loadingIndicatorToggle = true;
											if (i2cmessages.length === 0) {
												txid = await import2cloneid();
											} else {
												$loadingIndicatorToggle = false;
												openI2cmessage = true;
											}
										}}
									>
										{#if i2cmessages.length === 0}
											Insert&nbsp;in&nbsp;Perspective&nbsp;table
										{:else}
											Imported&nbsp;morphology&nbsp;profiles
										{/if}
									</Button>
								{/if}
							{/key}
						</Column>
					</Row>
					{#key txid}
						{#if txid}
							<Row>
								<Column>
									<InputRequestWebWorker
										{txid}
										apid={'m2.cellpose'}
										quid={'none'}
										clbk={async (x) => {
											tick = new Date();
											const pushed = x.evnt.PUSHED;

											if (!pushed) return;
											if (!pushed.length) return;
											const peventslength = pushed.length;
											for (let index = 0; index < peventslength; index++) {
												const pevent = pushed[index];
												const tic = (new Date()).getTime();
												const event = pevent.k;
												const content = pevent.v;

												notifk2 = content;
												if (!(x.evnt.AFIR && askforinputProps.show))
													rows.push({ id: rows.length, event: event, content: content });

												if (content) {
													const pipesplit = content.split('|');
													console.log("PIPESPLIT", tic, index++, pipesplit);
													
													switch (event) {
														case 'ABRT':
															break;

														case 'AFIQ':
															const afiq = JSON.parse(pipesplit[1]);
															const tmp_askforinputProps = {
																show: true,
																prompt: afiq.prompt[0],
																retry: afiq.retry_prompt[0],
																options: afiq.inputOptions,
																infomessage: afiq.infomessage.join('<br>'),
																infotype: afiq.inputType[0],
																txid: x.txid
															};
															$loadingIndicatorToggle = false;
															console.log(afiq, tmp_askforinputProps);
															askforinputProps = tmp_askforinputProps;
															break;



														case 'DONE':
															$loadingIndicatorToggle = !true;

															txid = undefined;
															return;
															break;

														case 'INFO':
															break;

														case 'JSON':
															if (pipesplit.length == 2) {
																const kv = pipesplit;
																if (kv[0] === 'SFS' || kv[0] === 'CSS'  || kv[0] === 'RDD' ) {
																	const finalres = JSON.parse(kv[1]);
																	console.log('JSON', kv[0] ,finalres);
																}
															}
															break;

														case 'MESG':
															break;

														case 'MSQL':
															break;

														case 'NTIF':
															let mess = '';
															console.log('content', content);
															console.log('NTIF', pipesplit);
															switch (pipesplit[0]) {
																case 'CSS':
																	mess = 'Clones scheduled for saving to database:';
																	break;
																case 'SFS':
																	{
																		const cc = parseInt(pipesplit[1]);
																		const cs = parseFloat(pipesplit[2]);
																		SFS += cc;
																		mess =
																			cc.toString() +
																			(cc > 1 ? ' clone(s) of size ' : ' clone of size ') +
																			cs.toString();
																	}
																	break;
																case 'RDD':
																	{
																		const cc = parseInt(pipesplit[1]);
																		RDD += cc;
																		mess =
																			cc.toString() +
																			(cc > 1
																				? ' clones already existed in database and were not saved again.'
																				: ' clone already existed in database and was not saved again.');
																	}
																	break;
															}
															i2cmessages.push(mess);
															i2cmessages = i2cmessages;
															console.log('MESS', mess);
															break;

														case 'PRNT':
															break;

														case 'QUIT':
															console.log('JobInfoWebWorker', event);
															return;
															break;

														case 'RSLT':
															openI2cmessage = true;
															$loadingIndicatorToggle = false;
															break;

														case 'VARS':
															const kv = pipesplit;
															$GlobPVARS[kv[0]] = JSON.parse(kv[1]);
															break;

														case 'WRNG':
															break;

														default:
															break;
													}
												}
											}
										}}
										pltm={500}
										show={true}
										{notif}
										loading={true}
									/>
								</Column>
							</Row>
						{/if}
					{/key}
				</Grid>
			</Tile>
		</Tile>
	{/if}
{/await}
<Modal
	hasScrollingContent
	bind:open={openI2cmessage}
	modalHeading="Imported morphology profiles"
	primaryButtonText="Ok"
	on:click:button--primary={() => (openI2cmessage = false)}
>
	{#key i2cmessages}
		<Tabs bind:selectedTab>
			<Tab label="Details" />
			<svelte:fragment slot="content">
				<TabContent>
					<Tile style="text-align:left;">
						<ul>
							{#each i2cmessages as i2cmessage}
								<li>
									{i2cmessage}
								</li>
							{/each}
						</ul>
					</Tile>
				</TabContent>
			</svelte:fragment>
		</Tabs>
	{/key}
</Modal>
