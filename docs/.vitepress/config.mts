import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'clawmetry-docker',
  description: 'Docker Image for clawmetry — real-time observability dashboard for OpenClaw AI agents.',

  base: '/clawmetry-docker/',

  ignoreDeadLinks: [/^http:\/\/localhost/],

  themeConfig: {
    logo: '/logo.png',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'Configuration', link: '/guide/configuration' },
          { text: 'Docker Compose', link: '/guide/docker-compose' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/stritti/clawmetry-docker' },
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © stritti',
    },
  },
})
