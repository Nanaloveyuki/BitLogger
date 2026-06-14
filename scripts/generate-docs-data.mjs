import { mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, dirname, extname, resolve } from 'node:path'

import matter from 'gray-matter'

const root = process.cwd()
const docsDir = resolve(root, 'docs')
const apiDir = resolve(docsDir, 'api')
const changesDir = resolve(docsDir, 'changes')
const outFile = resolve(docsDir, '.vitepress', 'generated', 'docs-data.mjs')

function splitWords(input) {
  return input
    .split(/[^A-Za-z0-9]+/)
    .map(part => part.trim())
    .filter(Boolean)
}

function formatWord(word) {
  const lower = word.toLowerCase()
  if (lower === 'api') return 'API'
  if (lower === 'json') return 'JSON'
  if (lower === 'js') return 'JS'
  if (lower === 'wasm') return 'WASM'
  if (lower === 'llvm') return 'LLVM'
  return lower.charAt(0).toUpperCase() + lower.slice(1)
}

function humanize(input) {
  const words = splitWords(input)
  if (words.length === 0) return input
  return words.map(formatWord).join(' ')
}

function extractTitle(source, fallback) {
  const heading = source.match(/^##\s+(.+)$/m)?.[1]?.trim()
  return humanize(heading ?? fallback)
}

function readApiDocs() {
  const entries = readdirSync(apiDir, { withFileTypes: true })
    .filter(entry => entry.isFile())
    .filter(entry => extname(entry.name) === '.md')
    .filter(entry => !entry.name.startsWith('.'))
    .map(entry => {
      const file = entry.name
      const slug = basename(file, '.md')
      const source = readFileSync(resolve(apiDir, file), 'utf8')
      const parsed = matter(source)
      const data = parsed.data
      const keywords = Array.isArray(data['key-word']) ? data['key-word'].map(String) : []
      return {
        file,
        slug,
        title: extractTitle(parsed.content, data.name ?? slug),
        name: String(data.name ?? slug),
        group: String(data.group ?? 'misc'),
        category: String(data.category ?? 'misc'),
        description: String(data.description ?? ''),
        updateTime: data['update-time'] == null ? '' : String(data['update-time']),
        keywords,
        link: `/api/${slug}`,
      }
    })
    .sort((left, right) => left.title.localeCompare(right.title))

  const grouped = [...new Set(entries.map(entry => entry.group))]
    .sort((left, right) => humanize(left).localeCompare(humanize(right)))
    .map(group => {
      const items = entries.filter(entry => entry.group === group)
      const categories = [...new Set(items.map(entry => entry.category))]
        .sort((left, right) => humanize(left).localeCompare(humanize(right)))
        .map(category => ({
          id: category,
          label: humanize(category),
          entries: items.filter(entry => entry.category === category),
        }))

      return {
        id: group,
        label: humanize(group),
        entryCount: items.length,
        categories,
      }
    })

  const categorySummaries = [...new Set(entries.map(entry => entry.category))]
    .sort((left, right) => humanize(left).localeCompare(humanize(right)))
    .map(category => ({
      id: category,
      label: humanize(category),
      entryCount: entries.filter(entry => entry.category === category).length,
    }))

  return {
    entries,
    groups: grouped,
    categories: categorySummaries,
  }
}

function readChanges() {
  return readdirSync(changesDir, { withFileTypes: true })
    .filter(entry => entry.isFile())
    .filter(entry => extname(entry.name) === '.md')
    .filter(entry => entry.name !== 'index.md')
    .map(entry => basename(entry.name, '.md'))
    .sort((left, right) => right.localeCompare(left, undefined, { numeric: true }))
    .map(version => ({
      version,
      link: `/changes/${version}`,
    }))
}

const api = readApiDocs()
const changes = readChanges()

const output = `export const docsData = ${JSON.stringify({ api, changes }, null, 2)}\n`
mkdirSync(dirname(outFile), { recursive: true })
writeFileSync(outFile, output)
