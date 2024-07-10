<script>
	/** @type {import('./$types').PageData} */

	import { page } from '$app/stores';

	const params = $page.url.searchParams;

	let d = {};
	for (const [k, v] of params) {
		d[k] = v;
	}
</script>

{#each params as [k, v]}
	<pre>
{k} - {v}	
</pre>
{/each}
