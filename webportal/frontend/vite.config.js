import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
	server: {
		host: true,
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
});


