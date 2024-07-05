import { redirect } from '@sveltejs/kit';

export function load() {
	throw redirect(307, '/module1/review20240124');
}
