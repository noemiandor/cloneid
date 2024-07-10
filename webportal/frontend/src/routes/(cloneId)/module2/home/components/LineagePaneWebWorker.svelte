<script>
	import { browser } from '$app/environment';
	import AskForBackendInputModal from '@/lib/components/modals/AskForBackendInputModal.svelte';
	import InputRequestWebWorker from '@/lib/components/ww/irww/InputRequestWebWorker.svelte';
	import { fetchImageInformation } from '@/lib/fetchdata/fetch';
	import {
		cleanSlate,
		sessionClear,
		sessionGet,
		sessionStore,
		setIconBGifExistingSession
	} from '@/lib/js/session';
	import { getUserHash } from '@/lib/mysql/getuserhash';
	import {
		GlobPVARS,
		genotypeShowPane,
		loadingIndicatorToggle,
		phenotypeShowOverlayImages,
		phenotypeShowPane,
		userName,
		waitingForAnswer
	} from '@/lib/storage/local/stores';
	import {
		Button,
		Column,
		ComboBox,
		DataTable,
		Form,
		Grid,
		InlineNotification,
		RadioButton,
		RadioButtonGroup,
		Row,
		TextInput,
		Tile
	} from 'carbon-components-svelte';
	import { Reset } from 'carbon-icons-svelte';
	import { onMount } from 'svelte';
	import Dropzone from 'svelte-file-dropzone';
	import CellposeResults from './CellposeResults.svelte';
	import ModalMissingAnswer from '@/lib/components/modals/ModalMissingAnswer.svelte';

	let from = '';
	let event = '';
	let imageId = '';
	let cellCount = '';
	let media = '';
	let flask = '';

	/**
	 * @type {number}
	 */
	let timeStamp = -1;

	/**
	 * @type {string | Blob}
	 */
	let userHash;
	/**
	 * @type {number}
	 */
	let dishSurfaceArea_cm2 = 0;

	let files = {
		accepted: [],
		rejected: [],
		confirmed: []
	};

	let insideDrop = false;

	/**
	 * @type {any[]}
	 */
	let flaskItems = [{ id: '0', text: ' ' }];

	/**
	 * @type {any[]}
	 */
	let mediaItems = [{ id: '0', text: ' ' }];

	// PHENOTYPE ENTRY FORM
	function populatePhenotypeFormEntriesFrom(entries) {
		from = entries.from;
		event = entries.event;
		imageId = entries.imageId;
		cellCount = entries.cellCount;
		timeStamp = entries.timeStamp;

		const mediaArray = entries.mediaArray;
		if (mediaArray) {
			const tmp_mediaItems = mediaArray.map((x) => {
				const text = `${x.id}, ${x.base1}, ${x.base1_pct}, ${x.base2}, ${x.base2_pct}, ${x.fbs}, ${x.fbs_pct}, ${x.energysource2}, ${x.energysource2_pct}, ${x.energysource}, ${x.energysource_nm}, ${x.hepes}, ${x.hepes_mm}, ${x.salt}, ${x.salt_nm}, ${x.antibiotic}, ${x.antibiotic_pct}, ${x.growthfactors}, ${x.antibiotic2}, ${x.antibiotic2_pct}, ${x.antimycotic}, ${x.antimycotic_pct}, ${x.stressor}, ${x.stressor_concentration}, ${x.stressor_unit}, ${x.comment}, ${x.antibiotic3}, ${x.antibiotic4}, ${x.antibiotic3_pct}, ${x.antibiotic4_pct}`;
				const regex = /[,]+/g;
				return { id: `${x.id}`, text: text.replaceAll(' 0', ' ').replaceAll('null', '').replaceAll(regex, '') };
			});
			mediaItems = tmp_mediaItems;
		} else {
			mediaItems = [{ id: '0', text: ' ' }];
		}
		const flaskArray = entries.flaskArray;
		if (flaskArray) {
			const tmp_flaskItems = flaskArray.map((x) => {
				if (entries.flask == x.id) {
					dishSurfaceArea_cm2 = x.dishSurfaceArea_cm2;
				}
				return {
					id: `${x.id}`,
					text: `${x.id},${x.manufacturer},${x.material},${x.dishSurfaceArea_cm2}cm2,${x.surface_treated_type},${x.bottom_shape}`
				};
			});
			flaskItems = tmp_flaskItems;
		} else {
			flaskItems = [{ id: '0', text: ' ' }];
		}

		flask = `${entries.flask}`;
		media = `${entries.media}`;
	}
	function clearPhenotypeFormEntries() {
		const clearEntries = {
			from: '',
			event: '',
			imageId: '',
			cellCount: '',
			timeStamp: ''
		};
		populatePhenotypeFormEntriesFrom(clearEntries);
	}

	// PHENOTYPE UPLOAD
	async function handleFilesForPhenotypeDropZone(lineageId) {
		cleanSlate();
		setIconBGifExistingSession();
		setLayoutifExistingSession();
		getUserHash();

		const entries = await fetchImageInformation(lineageId)
			.then((x) => {
				let FormEntries = {};
				const events = x.data.event;
				const media = x.data.media; //select DISTINCT id, base1, base1_pct, base2, base2_pct, fbs, fbs_pct, energysource2, energysource2_pct, energysource, energysource_nm, hepes, hepes_mm, salt, salt_nm, antibiotic, antibiotic_pct, growthfactors, antibiotic2, antibiotic2_pct, antimycotic, antimycotic_pct, stressor, stressor_concentration, stressor_unit, comment, antibiotic3, antibiotic4, antibiotic3_pct, antibiotic4_pct from CLONEID.Media order by base1 asc ;
				const flask = x.data.flask; //select DISTINCT id, manufacturer, material, dishSurfaceArea_cm2, surface_treated_type, bottom_shape from CLONEID.Flask order by manufacturer asc ;
				timeStamp = new Date().getTime(); // time stamp set 1
				if (events.length > 0) {
					const event = events[0];
					FormEntries = {
						from: event.passaged_from_id1,
						flask: event.flask,
						media: event.media,
						event: event.event,
						imageId: lineageId,
						cellCount: 'N/A',
						timeStamp: timeStamp.toString(),
						mediaArray: media,
						flaskArray: flask,
						dishSurfaceArea: dishSurfaceArea_cm2
					};
				} else {
					FormEntries = {
						from: undefined,
						flask: undefined,
						media: undefined,
						event: undefined,
						imageId: lineageId,
						cellCount: 'N/A',
						timeStamp: timeStamp.toString(),
						mediaArray: media,
						flaskArray: flask,
						dishSurfaceArea: undefined
					};
				}
				return FormEntries;
			})
			.catch((e) => {
				throw e;
			});
		return entries;
	}

	let preview_phenotype_files = false;
	let submitDisabled = false;

	/**
	 * @type {string}
	 */
	let selected_phenotype_event = '';
	let phenotype_event_and_color = [
		{ name: 'Harvest', value: 'harvest', color: 'red' },
		{ name: 'Seeding', value: 'seeding', color: 'blue' }
	];

	/**
	 * @type {string}
	 */

	onMount(async () => {
		cleanSlate();
		setIconBGifExistingSession();
		setLayoutifExistingSession();
		userHash = getUserHash();
	});

	let images_combined_sha512 = '';

	function decoderesponse(x) {
		const kv = JSON.parse(x.data);
		const k = kv[0];
		let d = {};
		for (let [k1, v1] of Object.entries(k)) {
			d[k1] = kv[v1];
		}
		return d;
	}

	/**
	 * @param {boolean} show
	 * @param {string} status
	 * @param {string} msg
	 * @param {string} notif
	 */
	let notif_key = '';
	let notifk1 = '';
	let notifk2 = '';
	async function mi_notif(k) {
		notif_key = k;
	}

	$: seginfo = {};

	$: cellpose_processing = cellpose_processing;

	let askforinputProps = {
		show: !true,
		prompt: 'Select:',
		retry: 'Invalid option',
		options: ['A', 'B', 'C'],
		infomessage: '',
		infotype: '',
		txid: 0,
		s: ''
	};
	$waitingForAnswer = false;
	/**
	 * @type {any}
	 */
	let txid = undefined;
	function reloadWindow() {
		window.location.href = window.location.href;
	}
	function resetLayout() {
		reloadWindow();
		$genotypeShowPane = true;
		$phenotypeShowPane = true;
		$phenotypeShowOverlayImages = !true;
	}
	function lineageOnlyLayout() {
		$genotypeShowPane = !true;
		$phenotypeShowPane = true;
		$phenotypeShowOverlayImages = !true;
	}
	function cellposeOnlyLayout() {
		$genotypeShowPane = !true;
		$phenotypeShowPane = !true;
		$phenotypeShowOverlayImages = true;
	}
	function multiOmicsOnlyLayout() {
		$genotypeShowPane = true;
		$phenotypeShowPane = !true;
		$phenotypeShowOverlayImages = !true;
	}

	$: notif = {};
	let jsondone = false;

	/**
	 * @param {{ [s: string]: any; } | ArrayLike<any>} x
	 */
	function DebugDumpObject(x) {
		let y = '';
		Object.entries(x).forEach((z) => {
			if (typeof z[1] === 'object') {
				y += `${z[0]}='{${DebugDumpObject(z[1])}}'\n`;
			} else {
				y += `${z[0]}='${z[1]}',\n`;
			}
		});
		return y;
	}
	$GlobPVARS = {};
	/**
	 * @type {any[]}
	 */
	// $:
	let rows = [];
	//  /**
	// 	 * @type {Date}
	// 	 */
	let tick;

	async function saveImgInfo() {
		const f = new FormData();
		f.append('s', images_combined_sha512);
		return await fetch('?/saveimginfo', { method: 'POST', body: f })
			.then(async (res) => {
				const x = await res.json();
				let d = {};
				if (x.status === 200) {
					d = decoderesponse(x);
					const processedi = await JSON.parse(d.imgs);
					return processedi;
				} else {
					throw x;
					console.log('X', x);
				}
			})
			.catch((e) => {
				console.log('saveseginfo', e);
				throw e;
			});
	}
	async function saveSegInfo() {
		if (!$GlobPVARS['seginfo']) {
			throw seginfo;
			return;
		}
		const f = new FormData();
		f.append('g', JSON.stringify($GlobPVARS));
		f.append('h', userHash);
		f.append('t', timeStamp.toString());
		await fetch('?/saveseginfo', { method: 'POST', body: f })
			.then(async (res) => {
				const x = await res.json();
				let d = {};
				if (x.status === 200) {
					d = decoderesponse(x);
					const processedl = d.date;
					const processedd = await JSON.parse(d.data);
					const processedi = await JSON.parse(d.imgs);
				} else {
					throw x;
					console.log('X', x);
				}
			})
			.catch((e) => {
				console.log('saveseginfo', e);
				throw e;
			});
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
				images_combined_sha512 = sessionGet('images_combined_sha512');
			}
		}
	}
	cleanSlate();
	setIconBGifExistingSession();
	setLayoutifExistingSession();
	userHash = getUserHash();

	function shouldFilterItem(item, value) {
		if (!value) return true;
		return item.text.toLowerCase().includes(value.toLowerCase());
	}
</script>

{#if $phenotypeShowPane}
	<Tile light>
		<!--  -->
		<!-- TITLE -->
		<!--  -->

		<Tile>
			<Tile light>
				<h5>
					Lineage Phenotype{selected_phenotype_event != '' ? ' - ' + selected_phenotype_event : ''}
					{#if selected_phenotype_event}
						<Button
							disabled={submitDisabled}
							kind="ghost"
							iconDescription="reset event"
							icon={Reset}
							size="small"
							on:click={() => {
								selected_phenotype_event = '';
								preview_phenotype_files = false;
							}}
						/>
					{/if}
				</h5>
			</Tile>

			<!--  -->
			<!-- NOTIFICATIONS -->
			<!--  -->

			{#if !true}
				{#key tick}
					<DataTable
						headers={[
							{ key: 'id', value: 'Id' },
							{ key: 'event', value: 'Event' },
							{ key: 'content', value: 'Content' }
						]}
						{rows}
					/>
			
				{/key}
				<hr />
			{/if}
			{#if txid}
				<InputRequestWebWorker
					{txid}
					apid={'m2.cellpose'}
					quid={'none'}
					clbk={async (x) => {
						tick = new Date();
						const events = x.evnt.EVENTS;
						const pushed = x.evnt.PUSHED;

						if (!pushed) return;
						if (!pushed.length) return;
						for (const pevent of pushed) {
							const event = pevent.k;
							const content = pevent.v;
							notifk2 = content;
							if (!(x.evnt.AFIR && askforinputProps.show))
								rows.push({ id: rows.length, event: event, content: content });

							if (content) {
								const pipesplit = content.split('|');
								const columnsplit = content.split('::');

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
											txid: x.txid,
											s: images_combined_sha512
										};
										$loadingIndicatorToggle = false;
										// console.log(afiq, tmp_askforinputProps);
										askforinputProps = tmp_askforinputProps;
										break;

									case 'AFIR':
										if (!true) {
											const p1 = columnsplit;
											const p2 = p1[2].split('|');
											$loadingIndicatorToggle = false;

											const tmp_askforinputProps = {
												show: true,
												prompt: p1[1],
												retry: p1[3],
												options: p2,
												infomessage: p1[4],
												infotype: p1[5],
												txid: x.txid
											};

											askforinputProps = tmp_askforinputProps;
										}
										break;

									case 'DONE':
										cellposeOnlyLayout();
										return;

									case 'INFO':
										break;

									case 'TIMT':
										askforinputProps.show = false;
										await new Promise((res) => setTimeout(res, 200));
										askforinputProps.show = true;
										await new Promise((res) => setTimeout(res, 100));
										askforinputProps.show = false;
										await new Promise((res) => setTimeout(res, 200));
										askforinputProps.show = true;
										$waitingForAnswer = true;
										break;

									case 'JSON':
										if (pipesplit.length == 2) {
											const kv = pipesplit;
											if (kv[0] === 'finalresult') {
												const finalres = JSON.parse(kv[1])[0];
												seginfo = {
													files: files,
													timestamp: timeStamp,
													t: timeStamp,
													userhash: userHash,
													h: userHash,
													s: images_combined_sha512,
													imageid: imageId,
													from: from,
													media: media,
													flask: flask,
													cellcount: cellCount,
													event: selected_phenotype_event,
													dishsurfacearea: dishSurfaceArea_cm2,
													flaskitems: flaskItems,
													mediaitems: mediaItems,
													waitforresult: 'N',
													results: finalres
												};
												$GlobPVARS['seginfo'] = seginfo;
												await saveSegInfo();
												storeLayout('segmentation');
												sessionStore('images_combined_sha512', images_combined_sha512);
												cellposeOnlyLayout();
												$loadingIndicatorToggle = false;
											}
										}
										break;

									case 'MESG':
										break;

									case 'MSQL':
										break;

									case 'NTIF':
										const status = pipesplit[0];
										const title = pipesplit[1];
										notif = { status: status, title: title };
										break;

									case 'PRNT':
										break;

									case 'QUIT':
										console.log('JobInfoWebWorker', event);
										$loadingIndicatorToggle = false;
										resetLayout();

										break;

									case 'RSLT':
										{
											const status = pipesplit[0];
											const title = pipesplit[1];
											if (status === 'IMGS') {
												const imgs = await saveImgInfo();
											}
										}
										break;

									case 'VARS':
										const kv = pipesplit;
										$GlobPVARS[kv[0]] = JSON.parse(kv[1]);
										break;

									case 'WRNG':
										notif = { status: pipesplit[0], title: pipesplit[1] };
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
				/>
			{/if}
			<Tile>
				<RadioButtonGroup
					disabled={submitDisabled}
					id="Ph"
					orientation="vertical"
					legendText="Event type"
					bind:selected={selected_phenotype_event}
					on:change={(e) => {
						mi_notif('D');
					}}
				>
					{#each phenotype_event_and_color as value}
						<RadioButton labelText={value.name} value={value.value} />
					{/each}
				</RadioButtonGroup>
				<br />
				<!--  -->
				<!-- SHOW DROPZONE OR FILES DOWNLOADED -->
				<!--  -->
				{#if preview_phenotype_files}
					<!--  -->
					<!-- SHOW FILES -->
					<!--  -->
					{#each files.confirmed as item, index}
						<div style="text-align:left;padding:3px;">
							Image {index + 1} :
							{item.fullname}
							<hr style="color: #efefef33;" />
						</div>
					{/each}
				{:else}
					<!--  -->
					<!-- SHOW DROPZONE -->
					<!--  -->
					<Dropzone
						on:drop={async (e) => {
							if (selected_phenotype_event === '') {
								alert('Select an event type, then try again.');
								e.preventDefault();
								$loadingIndicatorToggle = false;
								insideDrop = false;
								return;
							}
							const { acceptedFiles, fileRejections } = e.detail;
							let lineageId;
							const fileCount = acceptedFiles.length;
							if (fileCount == 0) {
								alert('No files dropped; Try again');
								selected_phenotype_event = '';
								e.preventDefault();
								$loadingIndicatorToggle = false;
								insideDrop = false;
								return;
							}
							if (!(fileCount >= 1 && fileCount <= 4)) {
								alert('Wrong file count; Try again');
								selected_phenotype_event = '';
								e.preventDefault();
								$loadingIndicatorToggle = false;
								insideDrop = false;
								return;
							}
							for (let index = 0; index < fileCount; index++) {
								const name = acceptedFiles[index].name;
								const breakAt = /_([0-9]+)x_ph_/;
								const splitted = name.split(breakAt);
								files.confirmed[index] = {
									fullname: name,
									name: splitted[0],
									timeStamp: timeStamp,
									shortname: splitted[0] + '...' + splitted[2]
								};
								if (index > 0) {
									if (files.confirmed[index].name != files.confirmed[index - 1].name) {
										console.log(files);
											files = {
												accepted: [],
												rejected: [],
												confirmed: []
											};
											console.log(files);
											alert('File names are inconsistent. Try again');
																					// alert('File name inconsistency; Try again');
										selected_phenotype_event = '';
										e.preventDefault();
										$loadingIndicatorToggle = false;
										insideDrop = false;
										return;
									}
								}
								lineageId = splitted[0];
							}

							await handleFilesForPhenotypeDropZone(lineageId).then(async (entries) => {
								if (!entries) {
									selected_phenotype_event = '';
									e.preventDefault();
									$loadingIndicatorToggle = false;
									return;
								}
								if (entries) {
									populatePhenotypeFormEntriesFrom(entries);
								} else {
									selected_phenotype_event = '';
									e.preventDefault();
									$loadingIndicatorToggle = false;
									return;
								}
								files.accepted = acceptedFiles;
								files.rejected = fileRejections;
								preview_phenotype_files = true;
							});
							insideDrop = false;
						}}
						containerStyles={insideDrop
							? 'outline-style: dotted; outline-color: green;    outline-width: 4px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #00ff0044;color: #111111; cursor:pointer; transition: border 1.24s ease-in-out;'
							: selected_phenotype_event
								? 'outline-style: dotted; outline-color: blue;    outline-width: 2px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #fbfbfb; color: #111111; cursor:copy; transition: border 0.24s ease-in-out;'
								: 'outline-style: dotted; outline-color: #f0f0f0; outline-width: 2px;  display: flex; flex-direction: column; align-items: center; padding: 20px; border-radius: 12px; background-color: #fbfbfb; color: #111111; cursor:not-allowed; transition: border 0.24s ease-in-out;'}
						on:dragenter={() => {
							clearPhenotypeFormEntries();
							if (
								selected_phenotype_event === 'harvest' ||
								selected_phenotype_event === 'seeding'
							) {
								insideDrop = true;
							}
						}}
						on:dragleave={() => {
							insideDrop = false;
						}}
						multiple
						noClick={selected_phenotype_event === '' ? true : false}
						disabled={false}
					>
						<span style={selected_phenotype_event === '' ? 'color:red;' : ''}>
							{selected_phenotype_event === ''
								? 'Select an event type then click or Drag and drop here to upload an image set'
								: 'Drag and drop files here or click to upload an image set'}
						</span>
					</Dropzone>
				{/if}
			</Tile>
			<!--  -->
			<!-- SHOW FORM -->
			<!--  -->
			{#if preview_phenotype_files === true && selected_phenotype_event !== ''}
				<Tile>
					<Form
						enctype="multipart/form-data"
						on:submit={async (e) => {
							$loadingIndicatorToggle = true;
							e.preventDefault();
							if (
								(selected_phenotype_event === 'harvest' &&
									!(imageId && from && cellCount && true)) ||
								(selected_phenotype_event === 'seeding' &&
									!(imageId && from && cellCount && media && flask && true))
							) {
								$loadingIndicatorToggle = false;
								alert('Missing information, try again.');
								selected_phenotype_event = '';
								preview_phenotype_files = false;
								return false;
							}
							submitDisabled = true;
							lineageOnlyLayout();
							userHash = getUserHash();
							let images_are_uploaded = false;
							let formData = new FormData();
							timeStamp = new Date().getTime(); // time stamp set 2
							formData.append('t', timeStamp.toString());
							formData.append('h', userHash.toString());
							for (let i = 0; i < files.accepted.length; i++) {
								formData.append(`f${i}`, files.accepted[i], files.accepted[i].name);
							}
							mi_notif('AUPLOADING');
							// <!--  -->
							// <!-- UPLOAD IMAGES -->
							// <!--  -->
							await fetch('?/uploadallphenotypeimages', {
								method: 'POST',
								body: formData
							})
								.then(async (res) => {
									const x = await res.json();
									let d = {};
									if (x.type === 'success' && x.status === 200) {
										d = decoderesponse(x);
										images_combined_sha512 = d.s;
										images_are_uploaded = d.c == files.accepted.length ? true : false;
										await mi_notif('FUPLOADED1000');
									} else {
										await mi_notif('EUPLOADING2000');
									}
								})
								.catch(async (e) => {
									console.log('uploads', e);
									await mi_notif('EUPLOADING2000');
								});

							if (images_are_uploaded && images_combined_sha512 !== '') {
								// <!--  -->
								// <!-- CELLPOSE PROCESS IMAGES -->
								// <!--  -->
								media = media === '0' ? 'NULL' : media;
								media = media ? media : 'NULL';
								flask = flask ? flask : 'NULL';
								cellCount = cellCount ? cellCount : 'NULL';

								formData = new FormData();
								for (let i = 0; i < files.accepted.length; i++) {
									formData.append(`f${i}`, files.accepted[i], files.accepted[i].name);
								}
								formData.append('timestamp', timeStamp.toString());
								formData.append('t', timeStamp.toString());
								formData.append('userhash', userHash.toString());
								formData.append('username', $userName.toString());
								formData.append('h', userHash.toString());
								formData.append('s', images_combined_sha512.toString());
								formData.append('imageid', imageId.toString());
								formData.append('from', from.toString());
								formData.append('media', media.toString());
								formData.append('flask', flask.toString());
								formData.append('cellcount', cellCount.toString());
								formData.append('event', selected_phenotype_event.toString());
								formData.append('dishsurfacearea', dishSurfaceArea_cm2.toString());
								formData.append('flaskitems', flaskItems.toString());
								formData.append('mediaitems', mediaItems.toString());
								formData.append('waitforresult', 'N'.toString());

								cellpose_processing = !false;

								const unused = await fetch('?/processphenotype', {
									method: 'POST',
									body: formData
								});

								const jinfo = await unused.json();
								const jinfod = decoderesponse(jinfo);
								txid = jinfod.i;
								$loadingIndicatorToggle = true;
							} else {
								await mi_notif('EPROCESSING3000');
								alert('Uploading Error');
								resetLayout();
								return false;
							}
							return true;
						}}
					>
						<Grid>
							<!-- ID and From -->
							<Row>
								<Column>
									<TextInput
										disabled={submitDisabled}
										light
										required
										bind:value={imageId}
										id="imageid"
										labelText="Id"
										placeholder="Id"
										autocomplete="imageid"
									/>
								</Column>
								<Column>
									<TextInput
										disabled={submitDisabled}
										light
										required
										bind:value={from}
										id="from"
										labelText="From"
										placeholder="From"
										autocomplete="from"
									/>
								</Column>
							</Row>
							<!-- Flask and Cellcount -->
							<Row>
								<Column style="text-align:left;">
									<!-- {flask} -->
									<ComboBox
										disabled={submitDisabled || selected_phenotype_event === 'harvest'}
										required
										light
										titleText="Flask"
										placeholder="Flask"
										bind:selectedId={flask}
										items={flaskItems}
										{shouldFilterItem}
									/>
								</Column>
								<Column>
									{#if isNaN(Number(cellCount)) && !(cellCount.toLowerCase() === 'n/a' || cellCount.toLowerCase() === 'na' || cellCount.toLowerCase() === 'nan' || false)}
										<InlineNotification kind="warning" lowContrast>
											<span slot="subtitle">Cellcount must be a number</span>
										</InlineNotification>
									{/if}
									<TextInput
										disabled={submitDisabled}
										light
										required
										bind:value={cellCount}
										id="cellcount"
										placeholder="0"
										labelText="Cellcount"
										autocomplete="cellcount"
									/>
								</Column>
							</Row>
							<!-- Media and Timestamp -->
							<Row>
								<Column style="text-align:left;">
									<!-- {media} -->
									<ComboBox
										disabled={submitDisabled}
										light
										titleText="Media"
										placeholder="Media"
										bind:selectedId={media}
										items={mediaItems}
										{shouldFilterItem}
									/>
								</Column>
								<Column>
									<TextInput
										light
										disabled
										required
										bind:value={timeStamp}
										id="timestamp"
										labelText="Timestamp"
										placeholder="Timestamp"
										autocomplete="timestamp"
									/>
								</Column>
							</Row>
							<!-- Cancel and Submit -->
							<Row style="text-align:center;">
								<Column>
									<Tile>
										<Button
											disabled={submitDisabled}
											kind="danger"
											on:click={(e) => {
												submitDisabled = false;
												clearPhenotypeFormEntries();
												selected_phenotype_event = '';
												preview_phenotype_files = false;
											}}><strong>Cancel</strong></Button
										>
										{#if selected_phenotype_event === 'harvest' || selected_phenotype_event === 'seeding'}
											<Button
												disabled={submitDisabled}
												type="submit"
												on:_click={(e) => {
													const formHasError = false;
													if (formHasError) {
														e.preventDefault();
													} else {
														// More errors?
														if (Number(cellCount) == 123) {
															// console.log('cellCount', cellCount);
															alert('Cellcount > available');
															e.preventDefault();
														}
													}
												}}><strong>Submit</strong></Button
											>
										{/if}
									</Tile>
								</Column>
							</Row>
						</Grid>
					</Form>
				</Tile>
			{/if}
		</Tile>
	</Tile>
{/if}

{#if $phenotypeShowOverlayImages}
	{#key images_combined_sha512}
		<CellposeResults id={images_combined_sha512} />
	{/key}
{/if}

{#key askforinputProps}
	<AskForBackendInputModal
		show={askforinputProps.show}
		prompt={askforinputProps.prompt}
		retry={askforinputProps.retry}
		options={askforinputProps.options}
		message={askforinputProps.infomessage}
		type={askforinputProps.infotype}
		txid={askforinputProps.txid}
		seg={askforinputProps.s}
	/>
{/key}
