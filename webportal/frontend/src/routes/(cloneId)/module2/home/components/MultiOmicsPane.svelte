<script>
	import { browser, dev } from '$app/environment';
	import ChartContainerSimplePie from '$lib/charts/containers/ChartContainerSimplePie.svelte';
	import { cleanSlate, sessionClear, sessionGet, sessionStore, setIconBGifExistingSession } from '@/lib/js/session';
	import { getUserHash } from '@/lib/mysql/getuserhash';
	import {
		certifieduser,
		genotypeShowPane,
		loadingIndicatorToggle,
		phenotypeShowOverlayImages,
		phenotypeShowPane,
		userName
	} from '@/lib/storage/local/stores';
	import {
		Button,
		DataTable,
		RadioButton,
		RadioButtonGroup,
		Tab,
		TabContent,
		Tabs,
		Tile
	} from 'carbon-components-svelte';
	import { CloseOutline, Reset } from 'carbon-icons-svelte';
	import * as JSsha512 from 'js-sha512';
	import { onMount } from 'svelte';
	import Dropzone from 'svelte-file-dropzone';

	/**
	 * @type {number}
	 */
	let timeStamp;
	/**
	 * @type {string | Blob}
	 */
	let userHash;

	let insideDrop_genotype = false;

	// GENOTYPE UPLOAD
	/**
	 * @param {CustomEvent<any>} e
	 */
	async function uploadFiles(e) {
		const { acceptedFiles, fileRejections } = e.detail;
		const fileCount = acceptedFiles.length;
		const timeStamp = new Date().toISOString();
		let uploaded = 0;
		const uniqNames = Array.from(
			new Set(
				acceptedFiles.map((x) => {
					return x.name.split('.')[0];
				})
			)
		);
		if (fileCount == 0) {
			return {
				uploaded: false,
				count: 0,
				timestamp: timeStamp,
				userhash: userHash,
				error: 'No files dropped; Try again'
			};
		}
		if (uniqNames.length !== 1) {
			return {
				uploaded: false,
				count: fileCount,
				timestamp: timeStamp,
				userhash: userHash,
				error: 'Incorrect file name; Try again'
			};
		}
		spstat_uniqName = uniqNames[0];
		for (let i = 0; i < fileCount; i++) {
			let formData = new FormData();
			formData.append('index', i.toString());
			formData.append('timestamp', timeStamp);
			formData.append('userhash', userHash);
			formData.append('file', acceptedFiles[i]);
			await fetch('?/uploadgenotype', {
				method: 'POST',
				body: formData
			})
				.catch((e) => {
					console.log('uploadFiles', e);
				});
			uploaded++;
		}
		return {
			uploaded: uploaded == fileCount,
			count: fileCount,
			timestamp: timeStamp,
			userhash: userHash,
			uniqName: uniqNames[0],
			error: 'Error uploading, please try again'
		};
	}

	// GENOTYPE PROCESS FILES
	/**
	 * @param {string} timeStamp
	 * @param {string} cellLine
	 * @param {string} perspective
	 */
	async function SPSTATS(timeStamp, cellLine, perspective) {
		cleanSlate();
		setIconBGifExistingSession();
		setLayoutifExistingSession();
		userHash = getUserHash();
		
		$loadingIndicatorToggle = true;
		let formData = new FormData();
		formData.append('timestamp', timeStamp);
		formData.append('userhash', userHash);
		formData.append('cellline', cellLine);
		formData.append('perspective', perspective);
		formData.append('cleanup', ($userName !== 'anonymous' ? "false":"true"));
		return await fetch('?/processgenotype', {
			method: 'POST',
			body: formData
		})
			.catch((e) => {
				console.log('uploadFiles', e);
			});
	}

	let preview_genotype = false;

	/**
	 * @type {string}
	 */
	let selected_genotype_pespective = '';
	let genotype_pespectives_and_color = [
		{ name: 'GenomePerspective', color: '#4a58dd' },
		{ name: 'ExomePerspective', color: '#27d7c4' },
		{ name: 'TranscriptomePerspective', color: '#95fb51' },
		{ name: 'KaryotypePerspective', color: '#ffa423' },
		{ name: 'MorphologyPerspective', color: '#ba2208' }
	];
	let start_spstats_upload = false;

	/**
	 * @type {{ name: string; value: any; }[]}
	 */
	let ChartContainerSimplePieData = [];

	/**
	 * @type {any[]}
	 */
	let tableRows = [];

	/**
	 * @type {string}
	 */
	let spstat_uniqName = '';
	$: SPSTATS_title_label = spstat_uniqName;
	SPSTATS_title_label = '';

	onMount(async () => {
		timeStamp = new Date().getTime();
		cleanSlate();
		setIconBGifExistingSession();
		setLayoutifExistingSession();
		userHash = getUserHash();

	});

	let shownotif = false;
	let inlineloading_status = 'active';
	let inlineloading_description = '';
	let notification_description = '<strong>HELLO</strong>';
	/**
	 * @param {boolean} show
	 * @param {string} status
	 * @param {string} msg
	 * @param {string} notif
	 */
	async function manage_inline_notif(show, status, msg, notif, wait = 0) {
		shownotif = show;
		inlineloading_status = status;
		inlineloading_description = msg;
		notification_description = notif;
		if (wait) {
			await new Promise((res) => setTimeout(res, wait)); // Wait a while
			shownotif = false;
		}
	}
	async function mi_notif(k) {
		let key = k;
		switch (key) {
			case 'D':
				manage_inline_notif(false, 'inactive', '', '');
				break;

			case 'D500':
				await manage_inline_notif(true, 'inactive', '', '', 500);
				break;

			case 'D1000':
				await manage_inline_notif(true, 'inactive', '', '', 1000);
				break;

			case 'IDONE1000':
				await manage_inline_notif(true, 'inactive', '', '<strong>Done</strong>', 1000);
				break;

			case 'ALOADING':
				manage_inline_notif(true, 'active', '', '<strong>loading</strong>');
				break;

			case 'AUPLOADING':
				manage_inline_notif(true, 'active', 'uploading', '<strong>uploading</strong>');
				break;

			case 'AUPLOADING1000':
				await manage_inline_notif(true, 'active', 'uploading', '<strong>uploading</strong>', 1000);
				break;

			case 'FLOADING1000':
				await manage_inline_notif(true, 'finished', '', '<strong>loading</strong>', 1000);
				break;

			case 'FUPLOADING1000':
				await manage_inline_notif(
					true,
					'finished',
					'uploading',
					'<strong>uploading</strong>',
					1000
				);
				break;

			case 'EUPLOADING2000':
				await manage_inline_notif(true, 'error', '', '<strong>error&nbsp;uploading</strong>', 2000);
				break;

			case 'FUPLOADED1000':
				await manage_inline_notif(true, 'finished', 'uploaded', '<strong>uploaded</strong>', 1000);
				break;

			case 'APROCESSING':
				manage_inline_notif(
					true,
					'active',
					'processing...',
					'<strong>processing&nbsp;images</strong>'
				);
				break;
			case 'APROCESSING2':
				manage_inline_notif(
					true,
					'active',
					'processing...',
					'<strong>processing&nbsp;images step 2</strong>'
				);
				break;

			case 'EPROCESSING3000':
				await manage_inline_notif(
					true,
					'error',
					'',
					'<strong>error&nbsp;processing</strong>',
					3000
				);
				break;

			case 'EPROCESSING8000':
				await manage_inline_notif(
					true,
					'error',
					'',
					'<strong>ERROR&nbsp;PROCESSING</strong>',
					8000
				);
				break;

			case 'EERROR3000':
				await manage_inline_notif(true, 'error', '', '<strong>error</strong>', 3000);
				break;

			case 'FDONE2000':
				await manage_inline_notif(true, 'finished', '', '<strong>done</strong>', 2000);
				break;

			default:
				break;
		}
	}

	function reloadWindow() {
		window.location.href = window.location.href;
	}
	function resetLayout() {
		reloadWindow();
		selected_genotype_pespective = '';
		SPSTATS_title_label = '';
		$loadingIndicatorToggle = false;
		$genotypeShowPane = true;
		$phenotypeShowPane = true;
		$phenotypeShowOverlayImages = !true;
	}
	function lineageOnlyLayout() {
		$genotypeShowPane = !true;
		$phenotypeShowPane = true;
		$phenotypeShowOverlayImages = !true;
	}
	function multiOmicsOnlyLayout() {
		$genotypeShowPane = true;
		$phenotypeShowPane = !true;
		$phenotypeShowOverlayImages = !true;
	}
	function cellposeOnlyLayout() {
		$genotypeShowPane = !true;
		$phenotypeShowPane = !true;
		$phenotypeShowOverlayImages = true;
	}

	let layout = undefined;

	/**
	 * @param {string} l
	 */
	function setLayout(l) {
		switch (l) {
			case 'home':
				resetLayout();
				break;
			case 'lineage':
				lineageOnlyLayout();
				break;
			case 'segmentation':
				cellposeOnlyLayout();
				break;
			case 'omics':
				multiOmicsOnlyLayout();
				break;
			default:
				break;
		}
	}
	/**
	 * @param {string} l
	 */
	function storeLayout(l) {
		sessionStore('layout', l);
	}
	/**
	 * @param {string} l
	 */
	function clearLayout(l) {
		sessionClear('layout');
	}
	function setLayoutifExistingSession() {
		if (browser) {
			const l = sessionGet('layout');
			if (l) {
				setLayout(l);
			}
		}
	}

	function decoderesponse(x) {
		const kv = JSON.parse(x.data);
		const k = kv[0];
		let d = {};
		for (let [k1, v1] of Object.entries(k)) {
			d[k1] = kv[v1];
		}
		return d;
	}
</script>

<Tile light>
	<Tile>
		<Tile light>
			<h5>
				Multi-Omics Genotype
				{SPSTATS_title_label || selected_genotype_pespective ? ' - ' : ''}
				{SPSTATS_title_label}
				{selected_genotype_pespective ? selected_genotype_pespective : ''}
				{#if selected_genotype_pespective && !start_spstats_upload}
					<Button
						kind="ghost"
						iconDescription="reset perspective"
						icon={Reset}
						size="small"
						on:click={() => {
							selected_genotype_pespective = '';
							SPSTATS_title_label = '';
						}}
					/>
				{/if}
				{#if selected_genotype_pespective && start_spstats_upload}
					<!-- <Button kind="danger-tertiary" iconDescription="reset" icon={TrashCan} size="small" on:click={()=>{selected_genotype_pespectives=null;}}/> -->
					<Button
						kind="ghost"
						iconDescription="reset"
						icon={CloseOutline}
						size="small"
						on:click={() => {
							preview_genotype = false;
							selected_genotype_pespective = '';
							SPSTATS_title_label = '';
						}}
					/>
				{/if}
			</h5>
		</Tile>

		<Tile>
			<div>
				{#if preview_genotype}
					<!-- Results -->
					<br />
					<Tabs>
						<Tab label="Graphic" />
						<Tab label="Data" />
						<svelte:fragment slot="content">
							<TabContent>
								<!-- PIE -->
								<ChartContainerSimplePie
									title={'clonal representation'}
									data={ChartContainerSimplePieData}
									completion={() => {}}
									size="md"
									HASH={`${1}-${22}-P`}
									_data={[]}
								/>
							</TabContent>
							<TabContent>
								<DataTable
									batchExpansion
									nonExpandableRowIds={tableRows
										.filter((row) => row.saved > 0)
										.map((row) => row.id)}
									headers={[
										{ key: 'name', value: 'Name' },
										{ key: 'saved', value: 'Profiles saved' }
									]}
									rows={tableRows}
								>
									<svelte:fragment slot="expanded-row" let:row>
										<pre>{JSON.stringify(row, null, 2)}</pre>
									</svelte:fragment>
								</DataTable>
							</TabContent>
						</svelte:fragment>
					</Tabs>
				{:else}
					<!-- Radio Buttons -->
					<RadioButtonGroup
						id="Ge"
						orientation="vertical"
						legendText="Perspective"
						bind:selected={selected_genotype_pespective}
					>
						{#each genotype_pespectives_and_color as value}
							<RadioButton labelText={value.name} value={value.name} />
						{/each}
					</RadioButtonGroup>
					<!-- DROPZONE -->
					<br />
					<Dropzone
						on:drop={async (e) => {
							if (selected_genotype_pespective === '') {
								alert('No perspective selected');
								e.preventDefault();
								$loadingIndicatorToggle = false;
								return;
							}
							$loadingIndicatorToggle = true;
							const uploaded = await uploadFiles(e).catch((e) => {
								alert('CATCH Error uploading, please try again');
							});
							if (!uploaded) {
								alert('Error uploading, please try again');
								e.preventDefault();
								selected_genotype_pespective = '';
								$loadingIndicatorToggle = false;
								return;
							}
							if (uploaded && !uploaded.uploaded && uploaded.error) {
								alert(uploaded.error);
								e.preventDefault();
								selected_genotype_pespective = '';
								$loadingIndicatorToggle = false;
								return;
							}
							if (uploaded && !uploaded.uploaded) {
								alert('Error uploading, please try again');
								e.preventDefault();
								selected_genotype_pespective = '';
								$loadingIndicatorToggle = false;
								return;
							}
							start_spstats_upload = true;
							const dir = await SPSTATS(
								uploaded.timestamp,
								uploaded.uniqName,
								selected_genotype_pespective
							).then(async (res) => {
								const result = await res.json();

								const data = decoderesponse(result);
								const r = JSON.parse(data.result);
								return r;
								const keys = data[0];
								return JSON.parse(data[1]);
							});
							if (Object.keys(dir.resultArray).length === 0) {
								alert(
									dir.file.toString() +
										' does not exist in table Passaging. Sample needs to be recorded in DB before adding omics-results to table Perspective.'
								);
								resetLayout();
								return;
							}
							ChartContainerSimplePieData = Object.keys(dir.resultArray)
								.sort()
								.map((x) => {
									return { name: `${x}`, value: dir.resultArray[x] };
								});
							let rowi = 1;
							tableRows = Object.keys(dir.resultArray)
								.sort()
								.map((x) => {
									return { id: `${rowi++}`, name: `${x}`, saved: dir.resultArray[x] };
								});
							preview_genotype = true;
							insideDrop_genotype = false;

							multiOmicsOnlyLayout();

							$loadingIndicatorToggle = false;
						}}
						on:click={async (e) => {
							if (selected_genotype_pespective === '') {
								e.preventDefault();
								e.stopImmediatePropagation();
								return;
							}
						}}
						containerStyles={insideDrop_genotype
							? 'outline-style: dotted; outline-color: green;    outline-width: 4px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #00ff0044;color: #111111; cursor:pointer; transition: border 1.24s ease-in-out;'
							: selected_genotype_pespective
								? 'outline-style: dotted; outline-color: blue;    outline-width: 2px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #fbfbfb; color: #111111; cursor:copy; transition: border 0.24s ease-in-out;'
								: 'outline-style: dotted; outline-color: #f0f0f0; outline-width: 2px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #fbfbfb; color: #111111; cursor:not-allowed; transition: border 0.24s ease-in-out;'}
						on:dragenter={() => {
							insideDrop_genotype = selected_genotype_pespective === '' ? false : true;
						}}
						on:dragleave={() => {
							insideDrop_genotype = false;
						}}
						multiple
						noClick={selected_genotype_pespective === '' ? true : false}
						disabled={false}
					>
						<span style={selected_genotype_pespective == '' ? 'color:red;' : ''}>
							{selected_genotype_pespective === ''
								? 'Select a perspective then click or Drag and drop here to upload a Spstats set'
								: 'Drag and drop files here or click to upload a Spstats set'}
						</span>
					</Dropzone>
				{/if}
			</div>
		</Tile>
	</Tile>
</Tile>
