<script>
	import { loadingIndicatorToggle } from '@/lib/storage/local/stores';

	import { InlineLoading, InlineNotification } from 'carbon-components-svelte';
	import { onMount } from 'svelte';
	import { fade, slide, blur, fly, scale } from 'svelte/transition';

	/**
	 * @type {any}
	 */
	export let txid = undefined;
	export let apid = undefined;
	export let quid = undefined;
	export let pltm = 10000;
	export let clbk = (x) => {};
	export let show = false;
	export let notif = {};
	export let loading = false;

	/**
	 * @type {string | undefined}
	 */
	let status = undefined;
	let workerrunning = false;
	/**
	 * @type {Worker | undefined}
	 */
	let wworker = undefined;
	$: wevent = { a: '', q: '', ww: '' };

	const onWwMessage = (/** @type {any} */ event) => {
		wevent = event.data;
		if (!wevent) return;
		if (wevent.ww === 'INIT') {
			status = 'active';
			status_description = 'processing';
			return;
		}
		if (typeof clbk === 'function') {
			clbk({
				txid: txid,
				apid: apid,
				quid: quid,
				pltm: pltm,
				evnt: wevent
			});
		}
		if (wevent.ww === 'DONE') {
			if (loading) {
				$loadingIndicatorToggle = !true;
			}
			status = 'finished';
			status = undefined;
			status_description = '';
			workerrunning = false;
			wworker = undefined;

			return;
		}
	};
	const loadWorker = async () => {
		wworker = new (await import('./ww?worker')).default();
		wworker.onmessage = onWwMessage;
		const data = {
			txid: txid,
			apid: apid,
			quid: quid,
			pltm: pltm
		};
		wworker.postMessage({ msg: 'init', data: data });
	};
	onMount(async () => {
		if (txid) loadWorker();
		if (loading) {
			$loadingIndicatorToggle = true;
		}
	});
	let status_description = 'processing';
</script>

{#if !loading}
	<div>
		{#if show}
				{#if ['active', 'inactive', 'finished', 'error'].includes(status)}
					{#if notif.status && !notif.title}
						<InlineLoading {status} description={'processing : ' + notif.status} />
					{:else}
						<InlineLoading {status} description={status_description} />
					{/if}
				{/if}
				{#key notif.title}
					{#if notif.status && notif.title}
						<InlineNotification
							lowContrast
							kind={notif.status}
							title={notif.title}
							statusIconDescription="info"
							closeButtonDescription="Close notification"
						/>
					{/if}
				{/key}
		{/if}
	</div>
{/if}
