import { sveltekit } from '@sveltejs/kit/vite';
<<<<<<< HEAD
=======
import { imagetools } from '@zerodevx/svelte-img/vite'
>>>>>>> master
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
	server: {
		host: true,
<<<<<<< HEAD
		port:8011,
		// port:80,
		fs: {
			// Allow serving files from one level up to the project root
			allow: ['.', '..'],
		},
	},
	plugins: [sveltekit()],
	resolve: {
		alias: {
		  '@': path.resolve(__dirname, './src'),
		  'components': path.resolve(__dirname, './src/components'),
		},
	  },
=======
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
>>>>>>> master
});


