<script>
	import {
		Button
	} from 'carbon-components-svelte';
<<<<<<< HEAD
</script>
<br />
<Button type="submit" href="/module1/">Home</Button>
=======
	export let href="/"
	export let label = "Home";
</script>
<br />
<Button href="{href}">{label}</Button>
>>>>>>> master
