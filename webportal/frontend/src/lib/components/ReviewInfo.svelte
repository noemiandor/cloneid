<script>
	import { Button, Tile } from 'carbon-components-svelte';
	import Close from 'carbon-icons-svelte/lib/Close.svelte';
	let showDescription = true;
</script>
{#if showDescription}
	<Tile light>
		<Button
			iconDescription="Close description"
			icon={Close}
			size="small"
			on:click={() => {
				showDescription = false;
			}}
		/>
        <slot name="content" />
	</Tile>
{/if}
