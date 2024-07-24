<script>
	import ModalLogOut from '$lib/components/modals/ModalLogOut.svelte';
	import ModaLogin from '$lib/components/modals/ModalLogin.svelte';
	import ModalLoginInvalid from '$lib/components/modals/ModalLoginInvalid.svelte';
	import { infos } from '$lib/data/review/links';
	import {
		cellInfo,
		cellInput,
		loadingIndicatorToggle,
		loginIconBGColor,
		showModalLogin,
		showModalLogout,
		userIsLoggedIn
	} from '$lib/storage/local/stores.js';
	import '@ibm/plex/scss/ibm-plex.scss';
	import {
		Content,
		Header,
		HeaderGlobalAction,
		HeaderUtilities,
		Loading,
		SideNav,
		SideNavDivider,
		SideNavItems,
		SideNavLink,
		SkipToContent
	} from 'carbon-components-svelte';
	import 'carbon-components-svelte/css/g10.css';
	import UserAvatarFilledAlt from 'carbon-icons-svelte/lib/UserAvatarFilledAlt.svelte';
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
	<meta name="theme-color" content="#f8f8f8" />

	<meta name="description" content="Clonid Module1/Moffitt/contract 23-MCC02420" />
	<meta name="author" content="Daniel Hannaby <legwork_02land@icloud.com>" />

	<meta charset="UTF-8" />
</svelte:head>

<Content style="padding:0px;height:100vh;">
	<Header
		company="CLONEiD"
		platformName=""
		bind:isSideNavOpen
		persistentHamburgerMenu={true}
		style="background-color:blue;"
		on:click={() => {
			$cellInfo = '';
			$cellInput = '';
		}}
	>
		<svelte:fragment slot="skip-to-content">
			<SkipToContent />
		</svelte:fragment>
		<HeaderUtilities>
			
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
	<SideNav
		bind:isOpen={isSideNavOpen}
		style="padding:0px;height:25vh;background-color:#f0f0f0;overflow:auto;border-style: solid; border-color:blue; border-width: 1px;"
	>
		<SideNavItems>
			{#each Object.keys(infos) as k}
				<SideNavLink
					text={`${k}:${infos[k].title}`}
					href={'#'}
					on:click={() => {
						$cellInfo = '';
						$cellInput = '';
						isSideNavOpen = false;
					}}
				/>
			{/each}
			<SideNavDivider />
		</SideNavItems>
	</SideNav>
	<slot />
</Content>
<ModaLogin />
<ModalLogOut />
<ModalLoginInvalid />
<Loading active={$loadingIndicatorToggle} />
