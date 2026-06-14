<script setup lang="ts">
import { computed } from 'vue'
import { withBase } from 'vitepress'

import { docsData } from '../../generated/docs-data.mjs'

const topCategories = computed(() => docsData.api.categories.slice(0, 6))
const recentChanges = computed(() => docsData.changes.slice(0, 4))
const apiCount = computed(() => docsData.api.entries.filter(entry => entry.slug !== 'index').length)
const groupCount = computed(() => docsData.api.groups.length)
</script>

<template>
  <section class="hub-grid">
    <article class="hub-panel hub-panel-accent">
      <p class="hub-eyebrow">Docs Hub</p>
      <h2 class="hub-title">Start from use case, not from filenames.</h2>
      <p class="hub-copy">
        Browse builders, runtime helpers, presets, sync logging, and async logging from one place.
      </p>
      <div class="hub-stats">
        <div>
          <strong>{{ apiCount }}</strong>
          <span>API pages</span>
        </div>
        <div>
          <strong>{{ groupCount }}</strong>
          <span>doc groups</span>
        </div>
        <div>
          <strong>{{ docsData.changes.length }}</strong>
          <span>release notes</span>
        </div>
      </div>
    </article>

    <article class="hub-panel">
      <p class="hub-eyebrow">Popular Areas</p>
      <ul class="hub-chip-list">
        <li v-for="category in topCategories" :key="category.id">
          <a class="hub-chip" :href="withBase('/api/')">
            <span>{{ category.label }}</span>
            <small>{{ category.entryCount }}</small>
          </a>
        </li>
      </ul>
    </article>

    <article class="hub-panel">
      <p class="hub-eyebrow">Release Trail</p>
      <ul class="hub-link-list">
        <li v-for="item in recentChanges" :key="item.version">
          <a :href="withBase(item.link)">Version {{ item.version }}</a>
        </li>
      </ul>
    </article>
  </section>
</template>

<style scoped>
.hub-grid {
  display: grid;
  gap: 1rem;
  margin: 1.5rem 0 2rem;
}

.hub-panel {
  border: 1px solid var(--vp-c-divider);
  border-radius: 24px;
  padding: 1.25rem;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.95), rgba(247, 245, 239, 0.95));
  box-shadow: 0 16px 40px rgba(62, 46, 31, 0.08);
}

.hub-panel-accent {
  background:
    radial-gradient(circle at top right, rgba(191, 68, 32, 0.16), transparent 34%),
    linear-gradient(180deg, rgba(255, 250, 244, 0.98), rgba(247, 241, 232, 0.98));
}

.hub-eyebrow {
  margin: 0 0 0.5rem;
  color: #9b4d28;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.75rem;
  font-weight: 700;
}

.hub-title {
  margin: 0;
  font-size: 1.55rem;
  line-height: 1.15;
}

.hub-copy {
  margin: 0.85rem 0 0;
  color: var(--vp-c-text-2);
}

.hub-stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.75rem;
  margin-top: 1.15rem;
}

.hub-stats strong,
.hub-stats span {
  display: block;
}

.hub-stats strong {
  font-size: 1.6rem;
}

.hub-stats span {
  color: var(--vp-c-text-2);
  font-size: 0.9rem;
}

.hub-chip-list,
.hub-link-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.hub-chip-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 0.7rem;
}

.hub-chip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  min-height: 56px;
  gap: 0.8rem;
  padding: 0.7rem 0.9rem;
  border-radius: 999px;
  text-decoration: none;
  color: inherit;
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid rgba(155, 77, 40, 0.14);
  box-sizing: border-box;
}

.hub-chip span {
  min-width: 0;
}

.hub-chip small {
  flex: 0 0 auto;
  color: var(--vp-c-text-2);
}

@media (max-width: 640px) {
  .hub-chip-list {
    grid-template-columns: 1fr;
  }
}

.hub-link-list {
  display: grid;
  gap: 0.5rem;
}

.hub-link-list a {
  color: var(--vp-c-brand-1);
  text-decoration: none;
}

@media (min-width: 860px) {
  .hub-grid {
    grid-template-columns: 1.35fr 1fr;
  }

  .hub-panel-accent {
    grid-row: span 2;
  }
}

@media (max-width: 640px) {
  .hub-stats {
    grid-template-columns: 1fr;
  }
}
</style>
