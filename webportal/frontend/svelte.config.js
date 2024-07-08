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
};

export default config;
