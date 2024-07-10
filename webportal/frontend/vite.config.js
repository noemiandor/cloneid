import { sveltekit } from '@sveltejs/kit/vite';
import { imagetools } from '@zerodevx/svelte-img/vite'
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
	server: {
		host: true,
		port: 8002,
		fs: {
			// Allow serving files from one level up to the project root
			allow: ['..'],
		},
		cors: true
	},
	plugins: [
		sveltekit(), imagetools()
	],
	resolve: {
		alias: {
			'@': path.resolve(__dirname, './src'),
			'WW@': path.resolve(__dirname, './src/lib/workers'),
			'components': path.resolve(__dirname, './src/components'),
			'components@': path.resolve(__dirname, './src/lib/components'),
		},
	},
});


