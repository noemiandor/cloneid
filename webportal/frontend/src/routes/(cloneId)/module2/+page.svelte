<script>
	//
	import { cleanSlate, setIconBGifExistingSession } from '$lib/js/session';
	import { linksAndTitles } from '$lib/data/review/links';
	import Module1 from '$lib/data/review/module1/overview/Module1.md';
	import Module1_1 from '$lib/data/review/module1/overview/Module1_1.md';
	import Module1_2a from '$lib/data/review/module1/overview/Module1_2a.md';
	import Module1_2b from '$lib/data/review/module1/overview/Module1_2b.md';
	import Module1_2c from '$lib/data/review/module1/overview/Module1_2c.md';
	import Module1_2d from '$lib/data/review/module1/overview/Module1_2d.md';
	import Module1_2e from '$lib/data/review/module1/overview/Module1_2e.md';
	import Module2_acceptance from '$lib/data/review/module1/overview/Module2_acceptance.md';
	import { ClickableTile, Column, Content, Grid, Row, Tile } from 'carbon-components-svelte';
	import { onMount } from 'svelte';
	onMount(async () => {
		cleanSlate();
		setIconBGifExistingSession();
	});
</script>
<svelte:head>
	<title>{linksAndTitles['overview'].title}</title>
</svelte:head>
<Content>
	<Grid fullWidth>
		<Row>
			<Column style="padding:1px;">
				<Tile light>
					<Module2_acceptance />
				</Tile>
			</Column>
		</Row>
	</Grid>
</Content>
