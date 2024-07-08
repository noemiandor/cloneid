<script>
	import { sessionClear, setIconBG } from '$lib/js/session';
	import {
		showModalLogout,
		userIsLoggedIn,
		userName,
		userPassword
	} from '$lib/storage/local/stores.js';
	import { Modal } from 'carbon-components-svelte';
</script>

<Modal
	danger
	size="sm"
	bind:open={$showModalLogout}
	modalHeading="Certified Users"
	primaryButtonText="Confirm"
	secondaryButtonText="Cancel"
	on:click:button--secondary={() => {
		$showModalLogout = false;
	}}
	on:click:button--primary={() => {
		$showModalLogout = false;
		$userIsLoggedIn = false;
		$userName = '';
		$userPassword = '';
		setIconBG(false);
		sessionClear('cloneid');
	}}
>
	Do you want to sign out?
</Modal>
