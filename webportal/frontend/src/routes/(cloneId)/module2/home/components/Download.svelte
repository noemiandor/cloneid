<script>
	import { Button, InlineLoading, Link } from 'carbon-components-svelte';
	import { sha512 } from "js-sha512";
	export let filename = '';
	export let id = '';
	export let type = 'b';
</script>

{#if id}
	{#if type === 'b'}
		<Button
		href={`/fep/${id}`}
		kind="tertiary"
		>
			Download&nbsp;"{filename}"&nbsp;results
		</Button>
	{:else if type === 'l'}
		<Link size="sm" href={`/fep/${id}`}>
			Download {filename}
		</Link>
	{/if}
{:else}
	<InlineLoading description="Creating {filename}" />
{/if}
