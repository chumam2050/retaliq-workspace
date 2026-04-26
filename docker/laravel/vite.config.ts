import { wayfinder } from '@laravel/vite-plugin-wayfinder';
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import laravel from 'laravel-vite-plugin';
import { defineConfig } from 'vite';

export default defineConfig({
    base: '/ws/', // CRITICAL: Tells Vite to serve assets from this path
    server: {
        host: '0.0.0.0',
        port: 5173, // Ensure this matches your Caddy upstream
        hmr: {
            host: 'esignature.retaliq.test',
            protocol: 'wss',
            clientPort: 443, // Forces browser to use port 443 instead of 5173
            path: 'ws'
        },
    },
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.tsx'],
            ssr: 'resources/js/ssr.tsx',
            refresh: true,
        }),
        react({
            babel: {
                plugins: ['babel-plugin-react-compiler'],
            },
        }),
        tailwindcss(),
        wayfinder({
            formVariants: true,
        }),
    ],
    esbuild: {
        jsx: 'automatic',
    },
});
