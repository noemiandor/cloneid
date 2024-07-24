<script>
	export let capabilities = {};
	export let addComponent = () => {};
	export const resized = () => {
		redraw();
	};

	import { browser } from '$app/environment';
	import { drawPedigreeTree } from '$lib/charts/components/PedigreeTree.js';
	import ChartContainerGenoUmap from '$lib/charts/containers/ChartContainerGenoUMAP.svelte';
	import ChartContainerGrowthCurve from '$lib/charts/containers/ChartContainerGrowthCurve.svelte';
<<<<<<< HEAD
	import ChartContainerTimetable from '$lib/charts/containers/ChartContainerTimetable.svelte';
	import ChartGenericImgContainer from '$lib/charts/containers/ChartGenericImgContainer.svelte';
	import ContextMenu from '$lib/components/ContextMenu.svelte';
	import Range from '$lib/components/Range.svelte';
	import ModalCellOrIdNotFound from '$lib/components/modals/ModalCellOrIdNotFound.svelte';
	import { count } from '$lib/js/count';
=======
	import ChartGenericImgContainer from '$lib/charts/containers/ChartGenericImgContainer.svelte';
	import ChartContainerTimetable from '$lib/charts/containers/ChartContainerTimetable.svelte';
	import ModalGenotypeInfo from '$lib/charts/modals/ModalGenotypeInfo.svelte';
	import ModalGrowthCurve from '$lib/charts/modals/ModalGrowthCurve.svelte';
	import ModalTimetable from '$lib/charts/modals/ModalTimetable.svelte';
	import ContextMenu from '$lib/components/ContextMenu.svelte';
	import ModalCellOrIdNotFound from '$lib/components/modals/ModalCellOrIdNotFound.svelte';
>>>>>>> master
	import {
		fetchGenotypeHEATMAPData,
		fetchGenotypePieData,
		fetchGenotypeUMAPData,
		fetchGrowthCurveData,
<<<<<<< HEAD
		fetchTimetableData
	} from '$lib/js/fetchdata/fetch.js';
=======
		fetchHarvestWithMorphologyInfo,
		fetchTimetableData,
		fetchTreeForCellId,
		fetchTreeForCellLine,
		fetchValidateCellorId
	} from '$lib/fetchdata/fetch.js';
>>>>>>> master
	import {
		cellInfo,
		cellInput,
		loadingIndicatorToggle,
		modalOpenGrowthCurve,
		pedigreetree,
		showModalCellOrIdNotFound
	} from '$lib/storage/local/stores.js';
	import {
		Button,
		ButtonSet,
<<<<<<< HEAD
		Form,
		OverflowMenu,
		OverflowMenuItem,
		TextInput
	} from 'carbon-components-svelte';
	import { SettingsView, ZoomIn, ZoomOut, ZoomReset } from 'carbon-icons-svelte';
	import CloseOutline from 'carbon-icons-svelte/lib/CloseOutline.svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';
	let rangeValue = null;
=======
		Column,
		Content,
		Form,
		Grid,
		Loading,
		OverflowMenu,
		OverflowMenuItem,
		Row,
		// Slider,
		TextInput,
		Tile,
		Toggle
	} from 'carbon-components-svelte';
	import CloseOutline from 'carbon-icons-svelte/lib/CloseOutline.svelte';
	import throttle from 'just-throttle';
	import { onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import { count } from '$lib/js/count';
	import { Add, SettingsView, ZoomFit, ZoomIn, ZoomOut, ZoomReset } from 'carbon-icons-svelte';
	import Range from '$lib/components/Range.svelte';
	import { decoderesponse } from '@/lib/js/misc';
	let rangeValue = null;
	let rangeTheme = 'default';
>>>>>>> master

	let treeDic = {};
	let cellLinePlaceHolder = 'Cell line or Lineage ID';

	let localZoomScale = 0;

	/**
	 * @type {HTMLDivElement}
	 */
	let pedigree_tree_wrapper;

	/**
	 * @type {number}
	 */
	let innerHeight;

	/**
	 * @type {number}
	 */
	let innerWidth;

	/**
	 * @type {number}
	 */
	let chartHeight;

	/**
	 * @type {number}
	 */
	let chartWidth;

	let tree;
	/**
	 * @type {{ collapse?: any; init: any; addTree: any; viewTree: any; }}
	 */
	let pInstance;
<<<<<<< HEAD

=======
>>>>>>> master
	/**
	 * @type {any[]}
	 */
	let pedigreeTable = [];

	/**
	 * @param {{ data: any; } | undefined} result
	 */
	function convertToNewick(result) {
<<<<<<< HEAD
=======
		console.log('result', result);
>>>>>>> master
		if (!result) return {};
		let kids = result;
		const kids2 = kids.sort(
			(
				/** @type {{ id: string; passage: number; }} */ a,
				/** @type {{ id: string; passage: number; }} */ b
			) => {
<<<<<<< HEAD
				const nameA = a.id.toUpperCase();
				const nameB = b.id.toUpperCase();
=======
				const nameA = a.id.toUpperCase(); // ignore case
				const nameB = b.id.toUpperCase(); // ignore case
>>>>>>> master
				const valA = a.passage;
				const valB = b.passage;
				if (valA == valB) {
					if (nameA < nameB) {
						return -1;
					} else {
						return 1;
					}
				}
				if (valA < valB) {
					return -1;
				} else {
					return 1;
				}
			}
		);
		let rootTree = null;

		/**
		 * @param {any} kids
		 * @param {string} x
		 */
		function gatherDescendants(kids, x) {
			/**
			 * @param {{ passaged_from_id1: string; }} y
			 */
			function checkPassage(y) {
				if (y.passaged_from_id1 == x) {
					return true;
				} else {
					return false;
				}
			}

			const ii = kids2.filter(checkPassage);
			if (ii.length === 0) {
				return '';
			}
			let newickTree = '(';
			for (let i of ii) {
				let y = gatherDescendants(kids, i.id);
				if (y.length > 0) {
					y += ':1,';
				}
				let dx = i.passage;
				newickTree += y + i.id + ':' + dx + ',';
			}
			newickTree = newickTree.replace(/,$/, ')');
			return newickTree;
		}

		const x = kids2[0].id;
		rootTree = gatherDescendants(kids2, x);
		return `(${rootTree}:1,${x}:1);`;
	}

	function startLoading() {
		$loadingIndicatorToggle = true;
	}

	function stopLoading() {
		$loadingIndicatorToggle = false;
	}

	/**
	 * @param {any} x
	 */
	function callbackC(x) {
		renderTree($pedigreetree);
	}

	/**
	 * @param {string} item
	 */
	function callbackM(item) {
		getPediGreeTreeFromCellOrId(item).then(async (tree) => {
			await prepareAndRender(tree);
		});
	}
	/**
	 * @param {any} item
	 */
	function callbackO(item) {
		pInstance.collapse(item);
	}
	async function callbackF(/** @type {string} */ name, /** @type {string} */ y) {
<<<<<<< HEAD

=======
		console.log('NAME', name, 'Y', y);
>>>>>>> master
		switch (y) {
			case 'pin_timetable':
				if (capableOf('Mt2')) pinTimeTable(name);
				break;
			case 'pin_growth':
				if (capableOf('Mc2')) pinGrowthCurve(name);
				break;
			case 'genomeperspective':
				pinGenotypeInfo(name, y);
				break;
			case 'transcriptomeperspective':
				pinGenotypeInfo(name, y);
				break;
			case 'karyotypeperspective':
				pinGenotypeInfo(name, y);
				break;
			case 'exomeperspective':
				pinGenotypeInfo(name, y);
				break;
			case 'morphologyperspective':
				pinGenotypeInfo(name, y);
				break;
			default:
				throw name;
				break;
		}
		return;
	}

	/**
	 * @param {string | number} name
	 */
	function callbackJ(name) {
		let enabledViews = {};
		let availableViews = [
			'curve',
			'timetable',
			'genomeperspective',
			'transcriptomeperspective',
			'karyotypeperspective',
			'exomeperspective',
			'morphologyperspective'
		].forEach((x) => {
			enabledViews[x] = false;
		});
<<<<<<< HEAD
		if (treeDic[name].count > 2) {
			enabledViews['curve'] = true;
		}
		if (treeDic[name].event == 'seeding') {
			enabledViews['timetable'] = true;
		}
		if (treeDic[name].whichPerspective) {
=======
		// if (lineageEventIds2[name] > 2) {
		if (treeDic[name].count > 2) {
			// Growth curve
			enabledViews['curve'] = true;
		}
		// if (lineageEventIds[name]) {
		if (treeDic[name].event == 'seeding') {
			// true => seeding, false => harvest
			enabledViews['timetable'] = true;
		}
		if (treeDic[name].whichPerspective) {
			// Have Genotype info
>>>>>>> master
			treeDic[name].whichPerspective
				.map((x) => {
					return x;
				})
				.forEach((perspective) => {
					enabledViews[perspective.toLowerCase()] = true;
				});
		}
<<<<<<< HEAD
=======
		// console.log(enabledViews);
>>>>>>> master
		return enabledViews;
	}

	let fitTree = false;

	/**
	 * @param {string} cap
	 */
	function capableOf(cap) {
		if (cap in capabilities) {
			return capabilities[cap];
		} else {
			return false;
		}
	}

<<<<<<< HEAD
=======
	let openContextM = false;
>>>>>>> master
	let zoomSetScale = null;
	let zoomSetData = null;

	/**
	 * @param {{ data: any; } | undefined} [pedigreeTree]
	 */
	function renderTree(pedigreeTree) {
		const treeSettings = {
			callbackA: function (/** @type {number} */ x) {
				localZoomScale = x;
				rangeValue = x;
			},
			callbackB: function (/** @type {any} */ x, /** @type {any} */ y) {
				zoomSetScale = x;
				zoomSetData = y;
				return;
			},
			callbackC: function (/** @type {boolean} */ x) {
				fitTree = x;
				renderTree($pedigreetree);
			},
			callbackD: function () {
				return HeightValue;
			},
			callbackE: function () {
				return capabilities;
			},
			callbackF: async function (/** @type {string} */ name, /** @type {string} */ y) {
<<<<<<< HEAD
=======
				console.log('NAME', name, 'Y', y);
>>>>>>> master
				switch (y) {
					case 'timetable':
						if (capableOf('Mt') || capableOf('Mt2')) drawTimeTable(name);
						break;
					case 'pin_timetable':
						if (capableOf('Mt2')) pinTimeTable(name);
						break;
					case 'growth':
						if (capableOf('Mc') || capableOf('Mc2')) drawGrowthCurve(name);
						break;
					case 'pin_growth':
						if (capableOf('Mc2')) pinGrowthCurve(name);
						break;
					case 'genotype':
<<<<<<< HEAD
						break;
					case 'pin_genotype':
=======
						// if (capableOf('Mg') || capableOf('Mg2')) drawAllGenotypeInfo(name);
						break;
					case 'pin_genotype':
						// if (capableOf('Mg2')) pinAllGenotypeInfo(name);
>>>>>>> master
						break;
					default:
						throw name;
						break;
				}
				return;
			},
			callbackG: function (/** @type {string | number} */ name) {
<<<<<<< HEAD
				return treeDic[name] && 'whichPerspective' in treeDic[name]
					? [...new Set(treeDic[name].whichPerspective)]
					: null;
=======
				// console.log('CALLBACKG', name, treeDic[name]);
				return treeDic[name] && 'whichPerspective' in treeDic[name]
					? [...new Set(treeDic[name].whichPerspective)]
					: null;
				if (!treeDic[name]) return false;
				return 'whichPerspective' in treeDic[name] ? true : false;
>>>>>>> master
			},
			callbackH: function (/** @type {string | number} */ name) {
				if (!treeDic[name]) return false;
				return treeDic[name].count > 2; // Growth curve
			},
			callbackI: function (/** @type {string | number} */ name) {
				if (!treeDic[name]) return false;
				return treeDic[name].event === 'seeding'; // true => seeding, false => harvest
			},
			callbackJ: function (/** @type {string | number} */ name) {
				if (!treeDic[name]) return false;
				let s = treeDic[name].event === 'seeding'; // true => seeding, false => harvest
				let g = treeDic[name].count > 2; // Growth curve
				let t = treeDic[name].whichPerspective ? true : false; // Have Genotype info
				return s || g || t;
			},
			callbackK: function (/** @type {number} */ x) {
				if (x == 0) {
					return fitTree;
				} else if (x == 1) {
					fitTree = !fitTree;
					return fitTree;
				}
			},
			callbackL: function (/** @type {any} */ x, /** @type {any} */ y) {
				if (contexComp && contexComp.callMenu && typeof contexComp.callMenu == 'function') {
					return contexComp.callMenu(x, y);
				}
			},
			callbackM: function (/** @type {string} */ item) {
<<<<<<< HEAD
=======
				// checkForCellOrLineageId(item); // JUMP HERE FEATURE
>>>>>>> master
				getPediGreeTreeFromCellOrId(item).then(async (tree) => {
					await prepareAndRender(tree);
				});
				return;
			},
			callbackN: function () {
				return [innerHeight, innerWidth];
<<<<<<< HEAD
=======
				return [chartHeight, chartWidth];
>>>>>>> master
			}
		};

		try {
			pInstance = drawPedigreeTree();
			pInstance.init(treeSettings);
<<<<<<< HEAD
=======
			// tree = pInstance.addTree(convertToNewick(pedigreeTree.rows));
>>>>>>> master
			tree = pInstance.addTree(convertToNewick(pedigreeTree));
			clear();
			pInstance.viewTree(tree.name, 'pedigreeTree', '');
			$pedigreetree = pedigreeTree;
		} catch (e) {
			$pedigreetree = null;
			console.error('Tree Render error', e);
		}
<<<<<<< HEAD
=======
		// stopLoading();
>>>>>>> master
	}

	function redraw() {
		startLoading();
		HeightValue = innerHeight;
		renderTree($pedigreetree);
		stopLoading();
	}

<<<<<<< HEAD
=======
	/**
	 * @param {string} text
	 */
	function setClipboard(text) {
		var type = 'text/plain';
		var blob = new Blob([text], { type });
		var data = [new ClipboardItem({ [type]: blob })];
		navigator.clipboard.write(data).then(
			function () {
				console.log('TO CLIPBOARD:', text);
				return;
			},
			function () {
				throw text;
			}
		);
	}

>>>>>>> master
	onMount(() => {
		clear();
	});

	/**
	 * @param {boolean} all
	 */
	function clear(all = false) {
		if (browser) {
			if (all) {
				$cellInfo = '';
				treeAvail = false;
			}
			if (pedigree_tree_wrapper)
				pedigree_tree_wrapper.innerHTML =
					'<div style="border-style: solid ; border-color: #000; border-width: 0px;' +
					'padding:0px;' +
					'background-color:' +
					'#f8f8f8' +
					';' +
<<<<<<< HEAD
					
=======
>>>>>>> master
					'height:' +
					`${HeightValue}` +
					'px;"' +
					' id="pedigreeTree"></div>';
<<<<<<< HEAD
					
=======
>>>>>>> master
		}
	}

	/**
	 * @param {string} item
	 */
	async function getPediGreeTreeFromCellOrId(item) {
		if (!item) {
			return [];
		}

		$cellInput = '';
		startLoading();
		let formData = new FormData();
		formData.append('item', item);

		return await fetch('?/getpedigreetree', {
			method: 'POST',
			body: formData
		})
			.then(async (res) => {
				const result = await res.json();
<<<<<<< HEAD
				const data = JSON.parse(result.data);
				const keys = data[0];
				return JSON.parse(data[keys['tree']]);
=======
				const x = decoderesponse(result);
				const tree = JSON.parse(x.tree);
				return tree;
>>>>>>> master
			})
			.catch((e) => {
				console.log('Analysis', e);
			})
			.finally(() => {
				stopLoading();
			});
	}

	/**
	 * @param {string} item
	 */
	async function checkForCellOrLineageIdWarmUp(item) {
		if (item) {
			await fetchValidateCellorId(item).then(async (value) => {
				const data = value.data;
				const length = data.length;
				if (length == 1) {
					const cellOrId = data[0];
					if (cellOrId['CellLine'] == true && cellOrId['CellId'] == false) {
						await fetchTreeForCellLine(item)
							.then(async (pedigreeTree) => {
								// pedigreeTable = pedigreeTree.data;
								await prepareToRenderWarmup(pedigreeTree);
								// .then(() => {
								// });
							})
							.catch((e) => {
								throw e;
							});
					} else if (cellOrId['CellLine'] == false && cellOrId['CellId'] == true) {
						$cellInfo = item;
						await fetchTreeForCellId(item)
							.then(async (pedigreeTree) => {
								// pedigreeTable = pedigreeTree.data;
								await prepareToRenderWarmup(pedigreeTree);
								// .then(() => {
								// });
							})
							.catch((e) => {
								throw e;
							});
					} else {
						throw item;
					}
				} else {
					throw item;
				}
			});
		}
	}

	/**
	 * @param {{ filter: (arg0: (y: any) => boolean) => { (): any; new (): any; length: any; }; }} p
	 * @param {string} x
	 */
	function countHarvest(p, x) {
		const h = p.filter(
			(/** @type {{ passaged_from_id1: any; }} */ y) => y.passaged_from_id1 === x
		).length;
		return h;
	}

	/**
	 * @param {any[] | undefined} tree
	 */
	function createEventList(tree) {
		if (!tree) {
			return [];
		}
		lineageEventIds = {};
		lineageEventIds2 = {};
		tree.forEach((/** @type {{ id: string | number; event: string; }} */ x) => {
			const cellId = x.id;
			lineageEventIds[cellId] = x.event == 'seeding' ? true : false;
			lineageEventIds2[cellId] = countHarvest(tree, x.id);

			x.count = countHarvest(tree, x.id);
		});
	}

<<<<<<< HEAD
=======
	async function setHavingGenotypeList_formaction() {
		let formData = new FormData();

		const perspectiveData = await fetch('?/perspectives', {
			method: 'POST',
			body: formData
		})
			.then(async (res) => {
				const result = await res.json(),
					data = JSON.parse(result.data),
					keys = data[0];
				return JSON.parse(data[keys['perspectives']]);
			})
			.catch((e) => {
				console.log('?/perspectives', e);
			});
		return perspectiveData;
	}

>>>>>>> master
	/**
	 * @param {string | Blob} sampleSource
	 */
	async function getPerspectiveData(sampleSource) {
		let formDataAllPespectives = new FormData();

		let allPerspectiveInfo = await fetch('?/perspectives', {
			method: 'POST',
			body: formDataAllPespectives
		})
			.then(async (res) => {
				const result = await res.json(),
					data = JSON.parse(result.data),
					keys = data[0];
				return JSON.parse(data[keys['perspectives']]);
			})
			.catch((e) => {
				console.log('?/perspectives', e);
			});

		let formDataAllMorphologyperspective = new FormData();
		formDataAllMorphologyperspective.append('samplesource', sampleSource);

		let morphologyperspective = await fetch('?/morphologyperspective', {
			method: 'POST',
			body: formDataAllMorphologyperspective
		})
			.then(async (res) => {
				const result = await res.json();
				const data = JSON.parse(result.data);
				const keys = data[0];
				return JSON.parse(data[keys['morphologyperspective']]);
			})
			.catch((e) => {
				console.log('?/morphologyperspective', e);
			});

		allPerspectiveInfo = [...allPerspectiveInfo, ...morphologyperspective];

		return allPerspectiveInfo;
	}

	/**
	 * @param {any} pedigreeTree
	 */
	async function prepareAndRender(pedigreeTree) {
		prepareToRender(pedigreeTree).then(() => {
			renderTree(pedigreeTree);
		});
	}
	$: perspectiveSet = new Set();
	/**
	 * @param {any} pedigreeTree
	 */
<<<<<<< HEAD
	async function prepareToRender(pedigreeTree) {
		treeDic = {};
		perspectiveSet = new Set();
=======
	async function prepareToRender(pedigreeTreeRows) {
							console.log('PEDIGREETREEROWS', pedigreeTreeRows);
		const pedigreeTree = pedigreeTreeRows;
		treeDic = {};
		perspectiveSet = new Set();
		// console.log('pedigreeTree', pedigreeTree);
		if (!pedigreeTree) {
			throw pedigreeTree;
		}
>>>>>>> master
		pedigreeTree.forEach((x) => {
			x.count = countHarvest(pedigreeTree, x.id);
			treeDic[x.id] = x;
		});

		const perspectiveList = await getPerspectiveData($cellInfo);
		perspectiveList.forEach((x) => {
<<<<<<< HEAD
=======
			// x.count = countHarvest(pedigreeTree, x.id);
>>>>>>> master
			if (treeDic[x.origin]) {
				const ps = perspectiveList
					.filter((y) => y.origin === x.origin)
					.map((x) => {
						perspectiveSet.add(x.whichPerspective);
						return x.whichPerspective;
					});
				treeDic[x.origin].whichPerspective = ps;
<<<<<<< HEAD
			}
		});
=======
				// x.whichPerspective;
			}
		});
		console.log('perspectiveList', perspectiveList);
		console.log('perspectiveSet', perspectiveSet);
>>>>>>> master
	}

	/**
	 * @param {any} pedigreeTree
	 */
	async function prepareToRenderWarmup(pedigreeTree) {
		prepareToRender(pedigreeTree).then(() => {
			// <!-- WARM CACHE START -->
			preparePedigreeTable(pedigreeTree);
<<<<<<< HEAD
			// <!-- WARM CACHE END -->
		});
	}

=======
			console.log('pedigreeTable', pedigreeTable);
			// <!-- WARM CACHE END -->
			// renderTree(pedigreeTree);
		});
	}

	let modalGenotypeLoaded = false;
	let modalGenotypeUUID = 0;
	let modalGenotypeCellId = '';
	let modalGenotypePerspective = '';
>>>>>>> master
	/**
	 * @type {never[]}
	 */
	let modalGenotypePerspectives = [];

	/**
	 * @param {string} query
	 */
<<<<<<< HEAD
	function pinGenotypeInfo(query, type) {
=======
	async function drawAllGenotypeInfo(query) {
		if (query) {
			modalGenotypePerspectives =
				//  havingGenotypeList[query]
				treeDic[query].whichPerspective.map((/** @type {{ perspective: any; }} */ x) => {
					return x.perspective;
				});
			startLoading();
			modalGenotypeLoaded = true;
			modalGenotypeCellId = query;
			modalGenotypeUUID = Math.floor(performance.now());
		}
	}

	/**
	 * @param {string} query
	 */
	function pinGenotypeInfo(query, type) {
		// console.log(query, type);
>>>>>>> master
		if (typeof addComponent === 'function') {
			if (query && type) {
				const p = {
					cellId: query,
					perspective: type
				};
				addComponent(ChartContainerGenoUmap, p);
			}
		}
<<<<<<< HEAD
		return;
	}

=======

		return;
	}

	/**
	 * @param {string} query
	 */
	function pinAllGenotypeInfo(query) {
		if (query) {

			treeDic[query].whichPerspective.forEach((/** @type {any} */ perspective) => {
				const p = {
					cellId: query,
					perspective: perspective
				};
				if (typeof addComponent === 'function') {
					if (query && perspective) {
						addComponent(ChartContainerGenoUmap, p);
					}
				}
			});
		}
		return;
	}
>>>>>>> master
	let modalTimeTableLoaded = false;
	let modalTimeTableUUID = 0;
	let modalTimeTableCellId = '';
	let modalTimeTablePerspective = '';

	/**
	 * @param {string} query
	 */
	function drawTimeTable(query) {
		if (query) {
			startLoading();
			modalTimeTableLoaded = true;
			modalTimeTableCellId = query;
			modalTimeTablePerspective = '';
			modalTimeTableUUID = Math.floor(performance.now());
		}
	}

	/**
	 * @param {string} query
	 */
	function pinTimeTable(query) {
<<<<<<< HEAD
=======
		console.log('QUERY', query);
>>>>>>> master
		if (query) {
			const p = {
				cellId: query
			};
			if (typeof addComponent === 'function') {
<<<<<<< HEAD
				if (query) addComponent(ChartContainerTimetable, p);
=======
				console.log('QUERY2', query);
				if (query) {
					console.log('QUERY3', query);
					addComponent(ChartContainerTimetable, p);
				}
>>>>>>> master
			}
		}
		return;
	}

	let modalGrowthCurveLoaded = false;
	let modalGrowthCurveUUID = 0;
	let modalGrowthCurveCellId = '';
	let modalGrowthCurvePerspective = '';

	/**
	 * @param {string} query
	 */
	function drawGrowthCurve(query) {
		if (query) {
			startLoading();
			modalGrowthCurveLoaded = true;
			modalGrowthCurveCellId = query;
			modalGrowthCurvePerspective = '';
			modalGrowthCurveUUID = Math.floor(performance.now());
			$modalOpenGrowthCurve = true;
		}
	}

	/**
	 * @param {string} query
	 */
	function pinGrowthCurve(query) {
		if (query) {
			const p = {
				cellId: query
			};
			if (typeof addComponent === 'function') {
				if (query) addComponent(ChartContainerGrowthCurve, p);
			}
		}
		return;
	}

	/**
	 * @param {string} query
	 */
	function pinTest(query) {
		if (typeof addComponent === 'function') {
			addComponent(ChartGenericImgContainer, { cellId: query });
		}
	}

	let l = '';
	$: {
		const x = localZoomScale.toString() || '1';
		l = x.slice(-1).valueOf() % 2 == 1 ? '. .' : '.';
	}
	stopLoading();
	/**
	 * @type {ContextMenu}
	 */
	let contexComp;

<<<<<<< HEAD
	// <!-- WARM CACHE START -->
=======
>>>>>>> master
	pedigreeTable = [];
	/**
	 * @param {any} pedigreeTree
	 */
	async function preparePedigreeTable(pedigreeTree) {
		pedigreeTable = pedigreeTree.map((x) => {
			const id = x.id;
			x.seeding = x.event === 'seeding';
			x.harvest = !x.seeding;
			x.harvestCount = x.count;
			x.genotypeInfo = x.whichPerspective ? x.whichPerspective : [];
			x.growthcurveCache = false;
			x.status = '';
			return x;
		});
	}

	/**
	 * @param {undefined} [item]
	 */
	async function warmUpCache(item) {
<<<<<<< HEAD

		const itemCount = pedigreeTable.length;
		const waitFor = 20;

		// fetchTree
		// console.log('fetchTree');
		if (false)
=======
		const itemCount = pedigreeTable.length;
		const waitFor = 20;

		if (!false)
>>>>>>> master
			for (let i = 0; i < itemCount; i++) {
				await new Promise((res) => setTimeout(res, waitFor));
				const cellId = pedigreeTable[i].id;
				console.log('Tree for cellId', cellId, i, 'of', itemCount);
				if (cellId) {
<<<<<<< HEAD
					// await checkForCellOrLineageIdWarmUp(cellId);
					await getPediGreeTreeFromCellOrId(cellId).then(async (tree) => {
						await prepareToRender(tree);
						// .then(() => {
						// 	pedigreeTable = tree;
						// 	renderTree(tree);
						// });
					});
				}
			}
		// return;

		// fetchGrowthCurveData
=======
					await getPediGreeTreeFromCellOrId(cellId).then(async (tree) => {
						await prepareToRender(tree);
					});
				}
			}
>>>>>>> master
		console.log('fetchGrowthCurveData');
		if (!false)
			for (let i = 0; i < itemCount; i++) {
				pedigreeTable[i].status = 'Loading';
				await new Promise((res) => setTimeout(res, waitFor));

				const cellId = pedigreeTable[i].id;
				console.log('GrowthCurve for cellId', cellId, i, 'of', itemCount);
<<<<<<< HEAD
				// console.log('601 cellId', cellId, i);
=======
>>>>>>> master
				if (cellId) {
					const ld = await fetchGrowthCurveData(cellId)
						.then((x) => {
							console.log(
								'fetchGrowthCurveData',
								i,
								cellId,
								x.data ? count(x.data) : 'ERROR',
								cellId
							);
						})
						.catch((e) => {
							console.log('fetchGrowthCurveData', i, cellId, e);
						});
				}

				pedigreeTable[i].status = '';
			}
<<<<<<< HEAD
		// return;

		// fetchTimetableData
=======
>>>>>>> master
		console.log('fetchTimetableData');
		if (!false)
			for (let i = 0; i < itemCount; i++) {
				pedigreeTable[i].status = 'Loading';
				await new Promise((res) => setTimeout(res, waitFor));

				const cellId = pedigreeTable[i].id;
				console.log('TimeTable for cellId', cellId, i, 'of', itemCount);
<<<<<<< HEAD
				// console.log('619 cellId', cellId, i);
=======
>>>>>>> master
				if (cellId) {
					const ld = await fetchTimetableData(cellId)
						.then((x) => {
							console.log(
								'fetchTimetableData',
								i,
								cellId,
								x.data ? count(x.data) : 'ERROR',
								cellId
							);
						})
						.catch((e) => {
							console.log('fetchTimetableData', i, cellId, e);
						});
				}
				pedigreeTable[i].status = '';
			}
<<<<<<< HEAD
		// return;

		// fetchGenotypePieData
		console.log('fetchGenotypePieData');
		if (!false)
=======
		console.log('fetchGenotypePieData');
		if (false)
>>>>>>> master
			for (let i = 0; i < itemCount; i++) {
				pedigreeTable[i].status = 'Loading';
				await new Promise((res) => setTimeout(res, waitFor));

				const cellId = pedigreeTable[i].id;
				console.log('GenotypePie for cellId', cellId, i, 'of', itemCount);
				const genotypeInfo = pedigreeTable[i].genotypeInfo;

				if (cellId && genotypeInfo && genotypeInfo.length) {
					for (const j in genotypeInfo) {
						const ld = await fetchGenotypePieData(cellId, genotypeInfo[j])
							.then((x) => {
								console.log(
									'fetchGenotypePieData',
									i,
									cellId,
									genotypeInfo[j],
									x.data ? count(x.data) : 'ERROR'
								);
							})
							.catch((e) => {
								console.log('fetchGenotypePieData', cellId, e);
							});
					}
				}
				pedigreeTable[i].status = '';
			}
		// return;

		// fetchGenotypeUMAPData
		console.log('fetchGenotypeUMAPData');
<<<<<<< HEAD
		if (!false)
=======
		if (false)
>>>>>>> master
			for (let i = 0; i < itemCount; i++) {
				pedigreeTable[i].status = 'Loading';
				await new Promise((res) => setTimeout(res, waitFor));

				const cellId = pedigreeTable[i].id;
				console.log('GenotypeUMAP for cellId', cellId, i, 'of', itemCount);
				const genotypeInfo = pedigreeTable[i].genotypeInfo;

				if (cellId && genotypeInfo && genotypeInfo.length) {
					for (const j in genotypeInfo) {
						console.log('659 cellId', cellId, genotypeInfo[j], i);
						const ld = await fetchGenotypeUMAPData(cellId, genotypeInfo[j])
							.then((x) => {
								console.log(
									'fetchGenotypeUMAPData',
									i,
									cellId,
									genotypeInfo[j],
									x.data ? count(x.data) : 'ERROR'
								);
							})
							.catch((e) => {
								console.log('fetchGenotypeUMAPData', cellId, e);
							});
					}
				}
				pedigreeTable[i].status = '';
			}
<<<<<<< HEAD
		// return;

		// fetchGenotypeHEATMAPData
		console.log('fetchGenotypeHEATMAPData');
		if (!false)
			for (let i = 0; i < itemCount; i++) {
				pedigreeTable[i].status = 'Loading';
				await new Promise((res) => setTimeout(res, waitFor));

				const cellId = pedigreeTable[i].id;
				console.log('GenotypeHEATMAP for cellId', cellId, i, 'of', itemCount);
				const genotypeInfo = pedigreeTable[i].genotypeInfo;

				if (cellId && genotypeInfo && genotypeInfo.length) {
					for (const j in genotypeInfo) {
						console.log('659 cellId', cellId, genotypeInfo[j], i);
						const ld = await fetchGenotypeHEATMAPData(cellId, genotypeInfo[j])
							.then((x) => {
								console.log(
									'fetchGenotypeHEATMAPData',
									i,
									cellId,
									genotypeInfo[j],
									x.data ? count(x.data) : 'ERROR'
								);
							})
							.catch((e) => {
								console.log('fetchGenotypeHEATMAPData', cellId, e);
							});
					}
				}
				pedigreeTable[i].status = '';
			}

		stopLoading();
	}
	// <!-- WARM CACHE END -->

	const showWarmup = false;
	const showButtonStack = false;
=======
	

		stopLoading();
	}

	const showWarmup = true;
	const showButtonStack = true;

>>>>>>> master

	$: treeAvail = false;
	let HeightValue = 0;
	$: HeightValue = innerHeight - 100;

	const perspectiveLabelColor = {
		GenomePerspective: '#4a58dd',
		ExomePerspective: '#27d7c4',
		TranscriptomePerspective: '#95fb51',
		KaryotypePerspective: '#ffa423',
		MorphologyPerspective: '#ba2208'
	};

	const bgmain = 'clear';
	const pdmain = '10px';
	let primaryfocus;

</script>

<svelte:head>
	<script type="text/javascript" src="/pedigreetree/js/jquery-2.1.4.min.js"></script>
	<script type="text/javascript" src="/pedigreetree/js/d3_3.5.17.min.js"></script>
	<link rel="stylesheet" type="text/css" href="/pedigreetree/css/style.css" />
</svelte:head>
<<<<<<< HEAD

=======
>>>>>>> master
<svelte:window bind:innerHeight bind:innerWidth on:resize={throttle(redraw, 1000)} />
<div style="background-color:{bgmain};height:100%;padding:{pdmain};">
	{#if $cellInfo}
		<div class="hasborder">
			<Button
				size="small"
				kind="danger-ghost"
				tooltipPosition="right"
				tooltipAlignment="end"
				iconDescription="Restart"
				icon={CloseOutline}
				on:click={() => {
					clear(true);
				}}><strong>{$cellInfo}</strong></Button
			>
<<<<<<< HEAD

=======
>>>>>>> master
			<div style="align-text:center; padding:2px;font-size:0.7rem;background-color:#ddd;">
				&nbsp;
				<span style="color:blue;font-weight:900;">Seeding</span> &dash;
				<span style="color:red;font-weight:900;">Harvest</span> &dash;
				{#if treeAvail}
					{#each perspectiveSet as perspective}
						<span style="color:{perspectiveLabelColor[perspective]};font-size:0.8rem;">◼︎</span
						><span style="font-weight:900;">{perspective}</span>
						&dash;
					{/each}
				{/if}
				<span style="font-size:1.0rem;">●</span><span style="font-weight:900;"
					>Growth&nbsp;curve</span
				>
				&dash;
				<span style="font-size:0.7rem;">▼</span><span style="font-weight:900;">Timetable</span>
			</div>

			<div style="font-size:2.0rem;align-self: flex-end; margin: 0 auto !important;">&nbsp;</div>

			<div style="font-size:2.0rem;align-self: flex-end; margin: 0 auto !important;">&nbsp;</div>

			<OverflowMenu
				flipped={true}
				size="sm"
				icon={SettingsView}
				on:click={() => {
					rangeValue = rangeValue;
				}}
			>
<<<<<<< HEAD
				
				<OverflowMenuItem hasDivider text="<br>" style="padding=10px;height:60px;">
					<div style="margin-bottom:20px;margin-top:20px;padding=0px;width:100%;">
						<br />
						Zoom <Range
							bind:value={rangeValue}
							on:change={(e) => {
=======
				<OverflowMenuItem hasDivider text="<br>" style="padding=10px;height:60px;">
					<div style="margin-bottom:20px;margin-top:20px;padding=0px;width:100%;">
						<br />

						Zoom <Range
							bind:value={rangeValue}
							on:change={(e) => {
								// console.log(zoomSetScale, zoomSetData, e.detail.value);
>>>>>>> master
								if (zoomSetScale && zoomSetData) zoomSetScale(e.detail.value, zoomSetData);
							}}
							min={0.05}
							max={2}
						/>

						<br />
					</div>
				</OverflowMenuItem>
				<OverflowMenuItem hasDivider text="<br>" style="padding=10px;height:60px;">
					<div style="margin-bottom:20px;margin-top:20px;padding=0px;width:100%;">
						<Button
							kind="tertiary"
							size="small"
							iconDescription="ZoomOut"
							icon={ZoomOut}
							disabled={rangeValue <= 0.05}
							on:click={(e) => {
								e.preventDefault();
								e.stopPropagation();
								if (rangeValue >= 0.02) {
									rangeValue /= 1.05;
								} else {
									rangeValue = 0.05;
								}
								if (zoomSetScale && zoomSetData) zoomSetScale(rangeValue, zoomSetData);
							}}
						/>
						<Button
							kind="tertiary"
							size="small"
							iconDescription="ZoomReset"
							disabled={rangeValue == 1}
							icon={ZoomReset}
							on:click={async (e) => {
								e.preventDefault();
								e.stopPropagation();
								rangeValue = 1;

								startLoading();
								fitTree = false;
								renderTree($pedigreetree);
								stopLoading();
								if (zoomSetScale && zoomSetData) zoomSetScale(rangeValue, zoomSetData);
							}}
						/>
						<Button
							kind="tertiary"
							size="small"
							iconDescription="ZoomIn"
							disabled={rangeValue >= 8}
							icon={ZoomIn}
							on:click={(e) => {
								e.preventDefault();
								e.stopPropagation();
								if (rangeValue <= 2.0) {
									rangeValue *= 1.05;
								} else {
									rangeValue = 2.0;
								}
								if (zoomSetScale && zoomSetData) zoomSetScale(rangeValue, zoomSetData);
							}}
						/>
<<<<<<< HEAD
=======

						<!-- <br /> -->
>>>>>>> master
					</div>
				</OverflowMenuItem>
				<OverflowMenuItem primaryFocus disabled text="" style="display:none;" />
			</OverflowMenu>
		</div>
		{#if showWarmup}
			<!-- WARM CACHE START -->
			<hr />
			<Button
				type="submit"
				on:click={async () => {
					startLoading();
<<<<<<< HEAD
					await getPediGreeTreeFromCellOrId($cellInfo).then(async (tree) => {
=======
					await getPediGreeTreeFromCellOrId($cellInfo)
					.then(async (tree) => {
>>>>>>> master
						await prepareToRenderWarmup(tree).then(() => {
							warmUpCache();
						});
					});
					stopLoading();
				}}
				>Warmup {$cellInfo}
			</Button>
			<!-- WARM CACHE END -->
		{/if}
		<hr />
<<<<<<< HEAD
=======
	
>>>>>>> master

		<div bind:this={pedigree_tree_wrapper}></div>

	{:else}
		<Form
			bind:this={primaryfocus}
			on:submit={async (e) => {
				startLoading();
				e.preventDefault();
				fitTree = false;
				$cellInfo = $cellInput;
<<<<<<< HEAD
				await getPediGreeTreeFromCellOrId($cellInput).then(async (tree) => {
					if (tree) {
						return await prepareToRender(tree).then(() => {
=======
				console.log($cellInput);
				await getPediGreeTreeFromCellOrId($cellInput)
				.then(async (tree) => {
					if (tree) {
						await prepareToRender(tree).then(() => {
>>>>>>> master
							pedigreeTable = tree;
							renderTree(tree);
						});
					} else {
						$showModalCellOrIdNotFound = true;
					}
				});
				$cellInput = '';
				await new Promise((r) => setTimeout(r, 1000));
				stopLoading();
				treeAvail = true;
			}}
		>
			<TextInput
				required
				bind:value={$cellInput}
				id="cellorlineageid"
				placeholder={cellLinePlaceHolder}
				autocomplete="cellorlineageid"
				size="xl"
				on:change={(e) => {
					e.preventDefault();
				}}
				autofocus
			/>
			<br />
			<Button type="submit">Submit</Button>


		</Form>

<<<<<<< HEAD
		{#if showWarmup}
			<!-- WARM CACHE START -->

			<hr />
			<Button
				type="submit"
				on:click={() => {
					warmUpCache();
				}}
				>WarmUp {$cellInfo} {$cellInput}
			</Button>

			<!-- WARM CACHE END -->
		{/if}
=======

>>>>>>> master
	{/if}
</div>

<ContextMenu bind:this={contexComp} {callbackC} {callbackM} {callbackF} {callbackJ} {callbackO} />
<ModalCellOrIdNotFound />
<span style="font-size:0.1em;color:#eeee;">{l}</span>

<style global lang="scss">
	.hasborder {
		display: flex;
		flex-direction: row;
		align-items: center;
		border-style: solid;
		border-color: #000;
		border-width: 0px;
		padding: 0px;
		vertical-align: middle;
		color: rgb(0, 0, 0);
		font-size: 0.3rem;
	}
<<<<<<< HEAD
	.hasborder0 {
		display: flex;
		flex-direction: row;
		align-items: center;
		border-style: solid;
		border-color: #000;
		border-width: 0px;
		padding: 3px;
		vertical-align: middle;
		color: rgb(0, 0, 0);
		font-size: 0.3rem;
	}
=======
>>>>>>> master
</style>
