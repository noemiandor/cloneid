<script>
	import {
		loginIconBGColor,
		showModalLogin,
		showModalLoginInvalid,
		userIsLoggedIn,
		userName,
		userPassword
	} from '$lib/storage/local/stores.js';
	import { sessionClear, sessionStore, setIconBG } from '$lib/js/session';
	import {
		Button,
		Column,
		FluidForm,
		Grid,
		Modal,
		PasswordInput,
		Row,
		TextInput,
		Tile
	} from 'carbon-components-svelte';
	import { env } from '$env/dynamic/public';

	/**
	 * @param {string} userName
	 * @param {string} passWord
	 */
	async function validateSQLCredentials(userName, passWord) {
		const now = new Date();

		const response = await fetch(env.PUBLIC_API_ENDPOINT_SQLAUTH, {
			method: 'POST',
			body: JSON.stringify({
				userName,
				passWord,
				now
			}),
			headers: {
				'content-type': 'application/json'
			}
		})
			.then((r) => {
				return r;
			})
			.catch((e) => {
				throw e;
			});

		return await response.json();
	}

	function checkLogin() {
		var auth = false;

		const z = validateSQLCredentials($userName, $userPassword)
			.then(
				function (value) {
					if ('sql' in value && value.sql == true) {
						auth = true;
						sessionStore('cloneid', 'on');
					} else {
						sessionClear('cloneid');
						auth = false;
					}
				},
				function (error) {
					auth = false;
					console.log('error=', error, 'auth=', auth);
				}
			)
			.finally(() => {
				$userName = '';
				$userPassword = '';

				if (auth) {
					$userIsLoggedIn = true;
					setIconBG(true);
					$showModalLoginInvalid = false;
					$showModalLogin = false;
				} else {
					$userIsLoggedIn = false;
					$loginIconBGColor = '';
					$showModalLoginInvalid = true;
				}
			});
	}
</script>

<Modal
	passiveModal
	bind:open={$showModalLogin}
	modalHeading="Certified Users Login"
	selectorPrimaryFocus="#user-name"
	size="sm"
>
	<Grid>
		<Row>
			<Column>
				<Tile>
					<FluidForm on:submit={checkLogin}>
						<TextInput
							light
							required
							bind:value={$userName}
							id="user-name"
							labelText="User Name"
							placeholder="Enter your CLONEiD user name..."
							autocomplete="username"
						/>
						<PasswordInput
							light
							tooltipAlignment="start"
							tooltipPosition="left"
							required
							bind:value={$userPassword}
							id="user-password"
							labelText="User Password"
							placeholder="Enter your CLONEiD password..."
							type="password"
							autocomplete="current-password"
						/>
						<Button type="submit">Submit</Button>
					</FluidForm>
				</Tile>
			</Column>
		</Row>
	</Grid>
</Modal>
