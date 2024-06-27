<script>
	import { env } from '$env/dynamic/public';
	import { setAuthorized } from '$lib/js/session';
	import { fetchUrl } from '@/lib/fetchdata/fetchUrl';
	import {
		Button,
		Form,
		Modal,
		TextInput
	} from 'carbon-components-svelte';

	export let show ;
	let pin = '';
	let auth = false;

	async function checkPin() {
		const now = new Date().toString();
		const p = { pin: pin, date: now };
		const response = await fetchUrl(env.PUBLIC_API_ENDPOINT_PINAUTH, 'get', p)
			.then(async (res) => {
				const x = await res.json();
				return x.data;
			})
			.catch((e) => {
				throw e;
			});

		setAuthorized();
		return response.result;
	}
</script>

<Modal
	passiveModal
	bind:open={show}
	modalHeading="Module2 Authorized User"
	selectorPrimaryFocus="#module2-pin"
	size="sm"
	on:close={async (e) => {
		if (!auth) {
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			await new Promise((res) => setTimeout(res, 300)); // Wait a while
			show = true;
		}
	}}
>
	<Form
		on:submit={async (e) => {
			auth = await checkPin();
			if (auth) {
				show = false;
				return;
			}
			show = true;
		}}
	>
		<TextInput
			required
			bind:value={pin}
			id="module2-pin"
			labelText="Module2 Pin"
			placeholder="Enter your Module2 pin..."
			autocomplete="module2-pin"
		/>
		<Button id="module2-pin-submit" type="submit">Submit</Button>
	</Form>
</Modal>
