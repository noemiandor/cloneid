<<<<<<< HEAD
import { vitePreprocess } from '@sveltejs/kit/vite';
import adapter from '@sveltejs/adapter-node';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  extensions: ['.svelte'],
	preprocess: [vitePreprocess()],
  kit: {
    adapter: adapter(),
		csrf: false,
  },
checkOrigin: false
=======
import { mdsvex } from 'mdsvex';
import mdsvexConfig from './mdsvex.config.js';
import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/kit/vite';
// import preprocess from 'svelte-preprocess';
// import precompileIntl from "svelte-intl-precompile/sveltekit-plugin";


/** @type {import('@sveltejs/kit').Config} */
const config = {
	extensions: ['.svelte', ...mdsvexConfig.extensions],
	// preprocess: [preprocess({ postcss: true, }), vitePreprocess(), mdsvex(mdsvexConfig)],
	// preprocess: [vitePreprocess(), mdsvex(mdsvexConfig), precompileIntl('locales')],
	preprocess: [vitePreprocess(), mdsvex(mdsvexConfig)],
	kit: {
		adapter: adapter(),
		csrf: false,
		serviceWorker: {
			register: false
		},
	},
	checkOrigin: false
>>>>>>> master
};

export default config;
