<script>
	import {
		Button
	} from 'carbon-components-svelte';
	export let href="/"
	export let label = "Home";
</script>
<br />
<Button href="{href}">{label}</Button>
