<script>
<<<<<<< HEAD
    import { cellInfo, showModalCellOrIdNotFound } from '$lib/storage/local/stores.js';
    import { Modal } from 'carbon-components-svelte';
</script>

<Modal 
    passiveModal 
    bind:open={$showModalCellOrIdNotFound} 
    modalHeading="Pedigree Tree - Id not Found"
    size="xs"
    on:close={(e)=>{$cellInfo='';}}
	>
	   
        
		<h5 style="text-align:center;color:red;"> Cell line or Lineage Id not found in database.</h5>
		<br>
		<h5 style="text-align:center;">Please try again </h5>

=======
	import { showModalCellOrIdNotFound } from '$lib/storage/local/stores.js';
	import { Modal, ToastNotification } from 'carbon-components-svelte';
</script>

<Modal passiveModal bind:open={$showModalCellOrIdNotFound} modalHeading="Pedigree Tree" size="xs">
	<ToastNotification
		hideCloseButton
		kind="error"
		title="Cell line or Lineage Id not found in database."
		subtitle="">Please try again</ToastNotification>
>>>>>>> master
</Modal>
