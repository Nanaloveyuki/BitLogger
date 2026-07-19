import { basename } from 'node:path'
import { createMoonbitLanguageRegistration } from 'moonbit-syntax-highlighter'
import { defineConfig, type DefaultTheme } from 'vitepress'

import { docsData } from './generated/docs-data.mjs'

type ApiDocEntry = {
  file: string
  text: string
  group: string
  category: string
}

const repoSlug = process.env.GITHUB_REPOSITORY?.split('/')[1] ?? 'BitLogger'
const docsBase = process.env.DOCS_BASE ?? (process.env.GITHUB_ACTIONS ? `/${repoSlug}/` : '/')
const repository = 'https://github.com/Nanaloveyuki/BitLogger'

function splitWords(input: string): string[] {
  return input
    .split(/[^A-Za-z0-9]+/)
    .map(part => part.trim())
    .filter(Boolean)
}

function formatWord(word: string): string {
  const lower = word.toLowerCase()
  if (lower === 'api') return 'API'
  if (lower === 'json') return 'JSON'
  if (lower === 'js') return 'JS'
  if (lower === 'wasm') return 'WASM'
  if (lower === 'llvm') return 'LLVM'
  return lower.charAt(0).toUpperCase() + lower.slice(1)
}

function humanize(input: string): string {
  const words = splitWords(input)
  if (words.length === 0) return input
  return words.map(formatWord).join(' ')
}

function readApiDocs(): ApiDocEntry[] {
  return docsData.api.entries.map(entry => ({
    file: entry.file,
    text: entry.title,
    group: entry.group,
    category: entry.category,
  }))
}

function buildApiSidebar(): DefaultTheme.SidebarItem[] {
  const entries = readApiDocs()
  const sidebar: DefaultTheme.SidebarItem[] = [{ text: 'Overview', link: '/api/' }]
  const groups = new Map<string, Map<string, DefaultTheme.SidebarItem[]>>()

  for (const entry of entries) {
    if (entry.file === 'index.md') continue
    const group = groups.get(entry.group) ?? new Map<string, DefaultTheme.SidebarItem[]>()
    const categoryItems = group.get(entry.category) ?? []
    categoryItems.push({
      text: entry.text,
      link: `/api/${basename(entry.file, '.md')}`,
    })
    group.set(entry.category, categoryItems)
    groups.set(entry.group, group)
  }

  if (groups.size === 1 && groups.has('api')) {
    const categories = groups.get('api')!
    for (const category of [...categories.keys()].sort((a, b) => humanize(a).localeCompare(humanize(b)))) {
      sidebar.push({
        text: humanize(category),
        collapsed: true,
        items: categories.get(category)!,
      })
    }
    return sidebar
  }

  for (const group of [...groups.keys()].sort((a, b) => humanize(a).localeCompare(humanize(b)))) {
    const categories = groups.get(group)!
    sidebar.push({
      text: humanize(group),
      collapsed: true,
      items: [...categories.keys()]
        .sort((a, b) => humanize(a).localeCompare(humanize(b)))
        .map(category => ({
          text: humanize(category),
          collapsed: true,
          items: categories.get(category)!,
        })),
    })
  }

  return sidebar
}

function buildChangesSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: 'Overview', link: '/changes/' },
    {
      text: 'Versions',
      items: docsData.changes.map(item => ({ text: item.version, link: item.link })),
    },
  ]
}

function buildExamplesSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: 'Overview', link: '/examples/' },
    { text: 'Console And Fields', link: '/examples/console' },
    { text: 'File Rotation', link: '/examples/file-rotation' },
    { text: 'Configuration', link: '/examples/config' },
    { text: 'Async Lifecycle', link: '/examples/async' },
  ]
}

function buildExtendSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: 'Overview', link: '/extend/' },
    { text: 'Queueing', link: '/extend/queue' },
    { text: 'Sink Composition', link: '/extend/composition' },
    { text: 'Text Formatting', link: '/extend/formatting' },
    { text: 'Target Boundaries', link: '/extend/targets' },
    { text: 'Trace Context', link: '/extend/observability' },
  ]
}

function buildChineseExamplesSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: '概览', link: '/zh/examples/' },
    { text: '控制台与结构化字段', link: '/zh/examples/console' },
    { text: '文件输出与轮转', link: '/zh/examples/file-rotation' },
    { text: '配置驱动构建', link: '/zh/examples/config' },
    { text: '异步日志生命周期', link: '/zh/examples/async' },
  ]
}

function buildChineseExtendSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: '概览', link: '/zh/extend/' },
    { text: '队列与溢出策略', link: '/zh/extend/queue' },
    { text: 'Sink 组合', link: '/zh/extend/composition' },
    { text: '文本格式与样式', link: '/zh/extend/formatting' },
    { text: '目标平台边界', link: '/zh/extend/targets' },
    { text: 'Trace Context', link: '/zh/extend/observability' },
  ]
}

function buildChineseApiSidebar(): DefaultTheme.SidebarItem[] {
  return [
    { text: '概览', link: '/zh/api/' },
    { text: '基础记录', link: '/zh/api/basics' },
    { text: '配置与队列', link: '/zh/api/configuration' },
    { text: '文件输出', link: '/zh/api/file-output' },
    { text: '文本格式', link: '/zh/api/formatting' },
    { text: '异步生命周期', link: '/zh/api/async' },
    { text: 'Sink 组合', link: '/zh/api/composition' },
  ]
}

const englishThemeConfig: DefaultTheme.Config = {
  siteTitle: 'BitLogger',
  nav: [
    { text: 'Home', link: '/' },
    { text: 'Examples', link: '/examples/' },
    { text: 'Extend', link: '/extend/' },
    { text: 'API', link: '/api/' },
    { text: 'Changes', link: '/changes/' },
    { text: 'Mooncake', link: 'https://mooncakes.io/docs/Nanaloveyuki/BitLogger' },
  ],
  search: {
    provider: 'local',
  },
  socialLinks: [{ icon: 'github', link: repository }],
  editLink: {
    pattern: `${repository}/edit/main/docs/:path`,
    text: 'Edit this page on GitHub',
  },
  sidebar: {
    '/examples/': buildExamplesSidebar(),
    '/extend/': buildExtendSidebar(),
    '/api/': buildApiSidebar(),
    '/changes/': buildChangesSidebar(),
  },
  footer: {
    message: 'Published from the repository docs folder with VitePress.',
    copyright: 'MIT',
  },
}

const chineseThemeConfig: DefaultTheme.Config = {
  siteTitle: 'BitLogger',
  nav: [
    { text: '首页', link: '/zh/' },
    { text: '示例', link: '/zh/examples/' },
    { text: '扩展', link: '/zh/extend/' },
    { text: 'API', link: '/zh/api/' },
    { text: '更新记录（英文）', link: '/changes/' },
    { text: 'Mooncake', link: 'https://mooncakes.io/docs/Nanaloveyuki/BitLogger' },
  ],
  search: {
    provider: 'local',
  },
  socialLinks: [{ icon: 'github', link: repository }],
  editLink: {
    pattern: `${repository}/edit/main/docs/:path`,
    text: '在 GitHub 上编辑此页',
  },
  sidebar: {
    '/zh/examples/': buildChineseExamplesSidebar(),
    '/zh/extend/': buildChineseExtendSidebar(),
    '/zh/api/': buildChineseApiSidebar(),
  },
  footer: {
    message: '由仓库中的 VitePress 文档构建。',
    copyright: 'MIT',
  },
}

export default defineConfig({
  title: 'BitLogger',
  description: 'Structured logging library docs for MoonBit.',
  base: docsBase,
  cleanUrls: true,
  srcExclude: ['dev/**'],
  lastUpdated: true,
  markdown: {
    languages: [createMoonbitLanguageRegistration()],
  },
  themeConfig: englishThemeConfig,
  locales: {
    root: {
      label: 'English',
      lang: 'en-US',
      themeConfig: englishThemeConfig,
    },
    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/zh/',
      themeConfig: chineseThemeConfig,
    },
  },
})
