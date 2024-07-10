<script>
	import { showModalCellOrIdNotFound } from '$lib/storage/local/stores.js';
	import { Modal, ToastNotification } from 'carbon-components-svelte';
</script>

<Modal passiveModal bind:open={$showModalCellOrIdNotFound} modalHeading="Pedigree Tree" size="xs">
	<ToastNotification
		hideCloseButton
		kind="error"
		title="Cell line or Lineage Id not found in database."
		subtitle="">Please try again</ToastNotification>
</Modal>
