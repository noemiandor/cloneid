<script>
	import {
		authorized,
		cleanSlate,
		clearAuthorized,
		setIconBGifExistingSession
	} from '$lib/js/session';
	import {
		loadingIndicatorToggle,
		loginIconBGColor,
		showModalLogin,
		showModalLogout,
		userIsLoggedIn,
		waitingForAnswer
	} from '$lib/storage/local/stores.js';

	import {
		certifieduser,
		userName,
		userPassword
	} from '$lib/storage/local/stores.js';

	import ModalLoginInvalid from '$lib/components/modals/ModalLoginInvalid.svelte';
	import ModalLogOut from '$lib/components/modals/ModalLogOut.svelte';
	import ModaLogin from '$lib/components/modals/ModalLogin.svelte';
	import { linksAndTitles } from '$lib/data/review/links';
	import { linksAndTitles2 } from '$lib/data/review/links';
	import '@ibm/plex/scss/ibm-plex.scss';
	import {
		Button,
		Header,
		HeaderGlobalAction,
		HeaderUtilities,
		Loading,
		SideNav,
		SideNavDivider,
		SideNavItems,
		SideNavLink,
		SkipToContent,
		Tile
	} from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
	import UserAvatarFilledAlt from 'carbon-icons-svelte/lib/UserAvatarFilledAlt.svelte';
	import { onMount } from 'svelte';
	import ModalMissingAnswer from '@/lib/components/modals/ModalMissingAnswer.svelte';
	import ModalAuthorized from '@/lib/components/modals/ModalAuthorized.svelte';
	let authorizedUser = false;
	onMount(async () => {
		cleanSlate();
		setIconBGifExistingSession();
		authorizedUser = authorized();
	});
	let isSideNavOpen = false;
	function loginMenu() {
		if ($userIsLoggedIn) {
			$showModalLogout = true;
		} else {
			$showModalLogin = true;
		}
	}
	$loadingIndicatorToggle = false;
</script>

<svelte:head>
	<link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-touch-icon.png" />
	<link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png" />
	<link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png" />
	<link rel="manifest" href="/favicon/site.webmanifest" />
	<link rel="mask-icon" href="/favicon/safari-pinned-tab.svg" color="#5bbad5" />
	<meta name="msapplication-TileColor" content="#da532c" />
	<meta name="theme-color" content="#ffffee" />
	<meta charset="UTF-8" />
</svelte:head>

<Loading active={$loadingIndicatorToggle} />

<Header
	company="CLONEiD"
	platformName=""
	bind:isSideNavOpen
	persistentHamburgerMenu={true}
	_href={linksAndTitles['overview'].href}
	href={'/module2/3_d'}
	style="background-color:blue;"
>
	<svelte:fragment slot="skip-to-content">
		<SkipToContent />
	</svelte:fragment>
	<HeaderUtilities>
		<h3 style="padding:7px;color:white;">MODULE 2</h3>
	</HeaderUtilities>
	<HeaderUtilities>
		{#if $certifieduser}
			<Button
				on:click={(e) => {
					e.preventDefault();
				}}>{$certifieduser}</Button>
		{:else}
			<Button
				kind="secondary"
				on:click={(e) => {
					e.preventDefault();
				}}>anonymous</Button>
		{/if}

		<HeaderGlobalAction
			icon={UserAvatarFilledAlt}
			style={$loginIconBGColor}
			on:click={(e) => {
				e.preventDefault();
				loginMenu();
			}}
		/>

	</HeaderUtilities>
</Header>
<SideNav bind:isOpen={isSideNavOpen}>
	<SideNavItems>
		{#each Object.keys(linksAndTitles2) as k}
			<!-- Left top bar Menu -->
			<SideNavLink
				_text={'Unused in testing mode'}
				text={linksAndTitles2[k].text}
				href={linksAndTitles2[k].href}
				on:click={() => {
					isSideNavOpen = false;
				}}
			/>
		{/each}
		<SideNavDivider />
	</SideNavItems>
</SideNav>
<!-- Main Content -->
<slot />
<ModaLogin />
<ModalLogOut />
<ModalLoginInvalid />
{#if !authorizedUser}
	<ModalAuthorized show={!authorizedUser} />
{/if}

{#key $waitingForAnswer}
	{#if $waitingForAnswer}
		<ModalMissingAnswer open={$waitingForAnswer} />
	{/if}
{/key}
