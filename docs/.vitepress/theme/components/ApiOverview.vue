<script setup lang="ts">
import { computed, shallowRef } from 'vue'

import { docsData } from '../../generated/docs-data.mjs'

const selectedGroup = shallowRef('all')
const query = shallowRef('')

const groups = computed(() => docsData.api.groups)

const filteredGroups = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  return groups.value
    .filter(group => selectedGroup.value === 'all' || group.id === selectedGroup.value)
    .map(group => ({
      ...group,
      categories: group.categories
        .map(category => ({
          ...category,
          entries: category.entries.filter(entry => {
            if (!keyword) return true
            const haystack = [entry.title, entry.description, entry.name, ...entry.keywords]
              .join(' ')
              .toLowerCase()
            return haystack.includes(keyword)
          }),
        }))
        .filter(category => category.entries.length > 0),
    }))
    .filter(group => group.categories.length > 0)
})

const resultCount = computed(() =>
  filteredGroups.value.reduce(
    (total, group) => total + group.categories.reduce((sum, category) => sum + category.entries.length, 0),
    0,
  ),
)
</script>

<template>
  <section class="api-shell">
    <div class="api-toolbar">
      <label class="api-search">
        <span>Find API</span>
        <input v-model="query" type="search" placeholder="Search logger, sink, config, async...">
      </label>

      <label class="api-filter">
        <span>Doc Group</span>
        <select v-model="selectedGroup">
          <option value="all">All groups</option>
          <option v-for="group in groups" :key="group.id" :value="group.id">
            {{ group.label }}
          </option>
        </select>
      </label>
    </div>

    <div class="api-summary">
      <strong>{{ resultCount }}</strong>
      <span>matching API pages across {{ filteredGroups.length }} group views</span>
    </div>

    <div class="api-groups">
      <article v-for="group in filteredGroups" :key="group.id" class="api-group-card">
        <header class="api-group-header">
          <div>
            <p class="api-group-kicker">{{ group.label }}</p>
            <h3>{{ group.entryCount }} APIs in this group</h3>
          </div>
        </header>

        <div class="api-category-grid">
          <section v-for="category in group.categories" :key="category.id" class="api-category-card">
            <h4>{{ category.label }}</h4>
            <p>{{ category.entries.length }} entries</p>
            <ul>
              <li v-for="entry in category.entries.slice(0, 8)" :key="entry.slug">
                <a :href="entry.link">{{ entry.title }}</a>
              </li>
            </ul>
            <a v-if="category.entries.length > 8" class="api-more" href="/api/">
              Browse {{ category.entries.length - 8 }} more in sidebar
            </a>
          </section>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.api-shell {
  margin: 1.5rem 0 2rem;
}

.api-toolbar {
  display: grid;
  gap: 0.9rem;
  margin-bottom: 1rem;
}

.api-search,
.api-filter {
  display: grid;
  gap: 0.4rem;
}

.api-search span,
.api-filter span {
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #9b4d28;
  font-weight: 700;
}

.api-search input,
.api-filter select {
  width: 100%;
  border-radius: 14px;
  border: 1px solid var(--vp-c-divider);
  background: rgba(255, 255, 255, 0.9);
  padding: 0.85rem 0.95rem;
  font: inherit;
}

.api-summary {
  display: flex;
  align-items: baseline;
  gap: 0.65rem;
  margin-bottom: 1rem;
}

.api-summary strong {
  font-size: 1.8rem;
}

.api-summary span {
  color: var(--vp-c-text-2);
}

.api-groups {
  display: grid;
  gap: 1rem;
}

.api-group-card {
  border: 1px solid var(--vp-c-divider);
  border-radius: 28px;
  padding: 1rem;
  background: linear-gradient(180deg, rgba(255, 251, 247, 0.96), rgba(246, 242, 236, 0.96));
}

.api-group-header h3,
.api-category-card h4,
.api-category-card p {
  margin: 0;
}

.api-group-kicker {
  margin: 0 0 0.25rem;
  color: #9b4d28;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-size: 0.75rem;
  font-weight: 700;
}

.api-category-grid {
  display: grid;
  gap: 0.85rem;
  margin-top: 0.9rem;
}

.api-category-card {
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.88);
  border: 1px solid rgba(155, 77, 40, 0.12);
  padding: 0.95rem;
}

.api-category-card p {
  margin-top: 0.25rem;
  color: var(--vp-c-text-2);
  font-size: 0.9rem;
}

.api-category-card ul {
  list-style: none;
  padding: 0;
  margin: 0.85rem 0 0;
  display: grid;
  gap: 0.45rem;
}

.api-category-card a {
  text-decoration: none;
}

.api-more {
  display: inline-block;
  margin-top: 0.8rem;
  color: var(--vp-c-text-2);
  font-size: 0.9rem;
}

@media (min-width: 820px) {
  .api-toolbar {
    grid-template-columns: minmax(0, 2fr) minmax(220px, 0.8fr);
  }

  .api-category-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
