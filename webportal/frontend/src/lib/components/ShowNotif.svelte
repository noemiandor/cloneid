<script>
	import { InlineLoading } from 'carbon-components-svelte';
	import { fade, slide, blur, fly, scale } from 'svelte/transition';

	export let shownotif = false;
	export let inlineloading_status = '';
	export let inlineloading_description = '';
	export let notification_description = '';
	export let notif_key = '';

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

	$: mi_notif(notif_key);
</script>

{#key shownotif}
	{#if shownotif}
		{#key inlineloading_status + inlineloading_description}
			<div
				style="padding:0px;padding-left:20px;padding-right:20px;outline-style: solid;
						outline-color:#22222222; outline-width:0px; display:flex; flex-direction: auto;
						align-items:center ; border-radius: 0px;  color: #111111;"
			>
				<InlineLoading status={inlineloading_status} description={inlineloading_description} />
				{#key notification_description}
					<div transition:scale>
						{@html notification_description}
					</div>
				{/key}
			</div>
		{/key}
	{/if}
{/key}
