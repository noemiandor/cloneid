<script>
	import {
<<<<<<< HEAD
=======
		certifieduser,
>>>>>>> master
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
<<<<<<< HEAD
	 */
	async function validateSQLCredentials(userName, passWord) {
		const now = new Date();
=======
	 * @param {number} force
	 */

	async function validateSQLCredentials(userName, passWord, force) {
		const now = new Date();
		if (force !== 0) {
			if (force === 1) {
				return { auth: true, username: 'user1' };
			}
			if (force === -1) {
				return { auth: false, username: '' };
			}
		}
>>>>>>> master

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
<<<<<<< HEAD
			.then((r) => {
				return r;
=======
			.then(async (r) => {
				let j = await r.json();
				j.username = userName;
				return j;
>>>>>>> master
			})
			.catch((e) => {
				throw e;
			});

<<<<<<< HEAD
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
=======
		return response;
		return await response.json();
	}

	async function checkLogin(force = 0) {
		var auth = false;

		const z = await validateSQLCredentials($userName, $userPassword, force)
			.then((value) => {
				return value;
			})
			.then(
				function (value) {
					auth = value.auth;
					$certifieduser = value.username;
>>>>>>> master
				},
				function (error) {
					auth = false;
					console.log('error=', error, 'auth=', auth);
				}
			)
			.finally(() => {
<<<<<<< HEAD
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
=======
				$userIsLoggedIn = auth;
				if (auth) {
					$showModalLogin = false;
					sessionStore('cloneid', 'on');
					sessionStore('user', $certifieduser);
				} else {
					sessionClear('cloneid');
					sessionClear('user');
				}
				setIconBG(auth);
				$showModalLoginInvalid = !auth;
				$userName = '';
				$userPassword = '';
>>>>>>> master
			});
	}
</script>

<<<<<<< HEAD
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
=======
{#key $showModalLogin}
	{#if $showModalLogin}
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
							<FluidForm
								on:submit={(e) => {
									console.log(e);
									checkLogin(0);
								}}
							>
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
								<Button
									type="submit"
									on:click={(x) => {
										console.log(x);
									}}>Submit</Button
								>
							</FluidForm>
						</Tile>
					</Column>
				</Row>
			</Grid>
		</Modal>
	{/if}
{/key}
>>>>>>> master
