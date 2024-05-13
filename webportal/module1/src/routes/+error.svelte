<script>
	import { page } from '$app/stores';
	import '@ibm/plex/scss/ibm-plex.scss';
	import { Content, Link, Tile } from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
</script>

<svelte:head>
	<title>{$page.status}</title>
</svelte:head>

<Content>
	<Tile>
		<h1>Err {$page.status}</h1>
		<h1>Page Not found!</h1>
	</Tile>
	<Tile light>
		<Link href="/">CLONEiD Module 1</Link>
	</Tile>
</Content>
