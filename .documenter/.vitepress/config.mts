import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import { mathjaxPlugin } from './mathjax-plugin'
import footnote from "markdown-it-footnote";
import path from 'path'

const mathjax = mathjaxPlugin()

function getBaseRepository(base: string): string {
  if (!base || base === '/') return '/';
  const parts = base.split('/').filter(Boolean);
  return parts.length > 0 ? `/${parts[0]}/` : '/';
}

const baseTemp = {
  base: '/JuliaHealthZoo/',// TODO: replace this in makedocs!
}

const navTemp = {
  nav: [
{ text: 'Home', link: '/index' },
{ text: 'Patient-Level Prediction', collapsed: false, items: [
{ text: 'Introduction', link: '/plp-intro' },
{ text: 'Examples', link: '/plp-examples' },
{ text: 'Setup and Cohort Building', link: '/plp-setup' },
{ text: 'Feature Engineering and Preprocessing', link: '/plp-features' },
{ text: 'Training and Evaluation', link: '/plp-modeling' }]
 },
{ text: 'Geospatial Health Informatics', link: '/geospatial' },
{ text: 'MRI Simulation and Analysis', link: '/mri' }
]
,
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker'
  }
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/JuliaHealthZoo/',// TODO: replace this in makedocs!
  title: 'JuliaHealthZoo',
  description: 'Documentation for JuliaHealthZoo',
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../1', // This is required for MarkdownVitepress to work correctly...
  head: [
    
    ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
    // ['script', {src: '/versions.js'], for custom domains, I guess if deploy_url is available.
    ['script', {src: `${baseTemp.base}siteinfo.js`}]
  ],
  
  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin);
      md.use(footnote);
      mathjax.markdownConfig(md);
    },
    theme: {
      light: "github-light",
      dark: "github-dark"
    },
  },
  vite: {
    plugins: [
      mathjax.vitePlugin,
    ],
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('/JuliaHealthZoo'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        // If there are other packages that need to be processed by Vite, you can add them here.
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },
  themeConfig: {
    outline: 'deep',
    
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav,
    sidebar: [
{ text: 'Home', link: '/index' },
{ text: 'Patient-Level Prediction', collapsed: false, items: [
{ text: 'Introduction', link: '/plp-intro' },
{ text: 'Examples', link: '/plp-examples' },
{ text: 'Setup and Cohort Building', link: '/plp-setup' },
{ text: 'Feature Engineering and Preprocessing', link: '/plp-features' },
{ text: 'Training and Evaluation', link: '/plp-modeling' }]
 },
{ text: 'Geospatial Health Informatics', link: '/geospatial' },
{ text: 'MRI Simulation and Analysis', link: '/mri' }
]
,
    editLink: { pattern: "https://github.com/JuliaHealth/JuliaHealthZoo/edit/main/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/JuliaHealth/JuliaHealthZoo' }
    ],
    footer: {
      message: 'Made with <a href="https://luxdl.github.io/DocumenterVitepress.jl/dev/" target="_blank"><strong>DocumenterVitepress.jl</strong></a><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})
