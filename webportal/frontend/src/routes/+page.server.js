import { redirect } from '@sveltejs/kit';

export function load() {
	throw redirect(307, '/module2/3_d');
}
