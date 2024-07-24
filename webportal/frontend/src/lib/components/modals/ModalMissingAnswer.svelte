<script>
	import { Modal, Tile } from 'carbon-components-svelte';
	export let open = true;
</script>

<Modal
	bind:open
	size="sm"
	modalHeading="Missing answers"
	primaryButtonText="Confirm"
	on:click:button--primary={() => {
		open = false;
	}}
>
	<Tile style="text-align:center;color:red;">
		<h2>
			<hr />
			You session will expire in 1 mn
			Please answer required questions
		</h2>
	</Tile>
</Modal>
