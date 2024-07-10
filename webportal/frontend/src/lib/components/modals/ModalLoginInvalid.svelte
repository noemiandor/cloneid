<script>
	import { showModalLoginInvalid, userName, userPassword } from '$lib/storage/local/stores.js';
	import { Modal, ToastNotification } from 'carbon-components-svelte';
</script>

<Modal
	passiveModal
	bind:open={$showModalLoginInvalid}
	modalHeading="Certified Users"
	size="xs"
	style="padding:0.5rem;"
	on:close={() => ($userName = $userPassword = '')}
>
	<ToastNotification
		hideCloseButton
		kind="error"
		title="Your credentials are invalid"
		subtitle="Please try again"
	/>
</Modal>
