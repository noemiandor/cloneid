<script>
	import { linksAndTitles } from '$lib/data/review/links';
	import { genotypeShowPane, phenotypeShowOverlayImages, phenotypeShowPane } from '@/lib/storage/local/stores';
	import { Button, Column, Grid, Row } from 'carbon-components-svelte';
	import LineagePaneWebWorker from './components/LineagePaneWebWorker.svelte';
	import MultiOmicsPane from './components/MultiOmicsPane.svelte';
	import CellposeResults from './components/CellposeResults.svelte';
	import { sessionClear } from '@/lib/js/session';

	$phenotypeShowPane = true;
	$genotypeShowPane = true;
	$phenotypeShowOverlayImages = !true;

</script>

<svelte:head>
	<title>{linksAndTitles['3.a'].title}</title>
</svelte:head>
<Grid fullWidth style="padding-top:60px;">
	<Row>
		<!--  -->
		<!-- LINEAGE PANE -->
		<!--  -->
			{#if $phenotypeShowPane || $phenotypeShowOverlayImages }
				<Column>
					<LineagePaneWebWorker />
				</Column>
			{/if}

		<!--  -->
		<!-- MULTIOMICS PANE -->
		<!--  -->
		{#key $genotypeShowPane}
			{#if $genotypeShowPane}
				<Column>
					<MultiOmicsPane />
				</Column>
			{/if}
		{/key}
	</Row>
	<Row>
		<Column>
			<hr style="opacity: 0.2;">
			<Button
				size="small"
				on:click={(x) => {
					sessionClear('layout');
					sessionClear('images_combined_sha512');
					window.location.href = window.location.href;
				}}
			>
				Home
			</Button>
		</Column>
	</Row>
</Grid>
