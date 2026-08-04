# Deployment Guide

Worry Box is a static frontend application, making deployment incredibly straightforward.

## Supported Platforms
- GitHub Pages
- Vercel
- Netlify
- Cloudflare Pages

## Deployment via Vercel (Recommended)
1. Push your code to the `master` or `main` branch on GitHub.
2. Log in to Vercel and click "Add New Project".
3. Import the `Worry-Box` repository.
4. If using Vite, Vercel will auto-detect the framework.
   - Build Command: `npm run build`
   - Output Directory: `dist`
5. Click "Deploy".

## Manual Build
To generate static files for manual hosting:
```bash
npm run build
```
Upload the contents of the generated `dist/` directory to any static web host.
