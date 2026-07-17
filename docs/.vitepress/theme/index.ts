import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'

import ApiOverview from './components/ApiOverview.vue'
import HomeDocHub from './components/HomeDocHub.vue'

import './custom.css'

const localePreferenceKey = 'bitlogger-docs-locale'

function routePath(path: string): string {
  return path.split(/[?#]/, 1)[0]
}

function isLocaleRoot(path: string): boolean {
  const normalized = routePath(path)
  return normalized === '/' || normalized === '/zh/'
}

function browserPrefersChinese(): boolean {
  return navigator.languages.some(language => language.toLowerCase().startsWith('zh'))
}

const theme: Theme = {
  extends: DefaultTheme,
  enhanceApp({ app, router }) {
    app.component('ApiOverview', ApiOverview)
    app.component('HomeDocHub', HomeDocHub)

    if (typeof window === 'undefined') return

    router.onAfterRouteChange = to => {
      if (!isLocaleRoot(to)) return
      window.localStorage.setItem(localePreferenceKey, routePath(to) === '/zh/' ? 'zh' : 'en')
    }

    if (router.route.path !== '/') return

    const savedLocale = window.localStorage.getItem(localePreferenceKey)
    const locale = savedLocale === 'zh' || savedLocale === 'en'
      ? savedLocale
      : browserPrefersChinese()
        ? 'zh'
        : 'en'

    if (locale === 'zh') {
      void router.go('/zh/')
    }
  },
}

export default theme
