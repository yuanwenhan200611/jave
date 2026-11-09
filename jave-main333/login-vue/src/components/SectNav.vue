<template>
  <nav class="navbar">
    <div class="nav-brand" @click="go('home')">
      <span class="nav-mark">
        <svg viewBox="0 0 48 48" fill="none" stroke="#e8c66a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 4 40 14v20L24 44 8 34V14z" />
          <path d="M24 14 32 18v12l-8 4-8-4V18z" opacity=".7" />
          <circle cx="24" cy="24" r="3.4" fill="#e8c66a" stroke="none" />
        </svg>
      </span>
      <span class="nav-title">逆天魔宗</span>
    </div>

    <ul class="nav-links">
      <li
        v-for="item in navItems"
        :key="item.key"
        :class="{ active: item.key === active }"
        @click="go(item.key)"
      >
        {{ item.label }}
      </li>
    </ul>

    <div class="nav-user">
      <span class="avatar">{{ avatarChar }}</span>
      <span class="uname">{{ username }}</span>
      <button class="logout" type="button" @click="emit('logout')">退 出</button>
    </div>
  </nav>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  active: { type: String, default: 'home' },
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const navItems = [
  { key: 'home', label: '首页' },
  { key: 'secret', label: '秘境' },
  { key: 'skill', label: '功法阁' },
  { key: 'rank', label: '宗门榜' },
  { key: 'forum', label: '论道' }
]

const avatarChar = computed(() => (props.username ? props.username.slice(0, 1).toUpperCase() : '道'))

function go(key) {
  emit('nav', key)
}
</script>

<style scoped>
.navbar {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 14px 28px;
  background:
    linear-gradient(120deg, rgba(200, 16, 46, .22), rgba(18, 10, 24, .72) 60%),
    rgba(12, 8, 18, .55);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--border-strong);
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  letter-spacing: 3px;
  color: var(--gold-soft);
  flex-shrink: 0;
  cursor: pointer;
}

.nav-mark {
  width: 32px;
  height: 32px;
  border-radius: 9px;
  background: rgba(0, 0, 0, .35);
  border: 1px solid rgba(212, 175, 55, .55);
  display: grid;
  place-items: center;
  box-shadow: 0 0 16px rgba(212, 175, 55, .25);
}

.nav-mark svg { width: 18px; height: 18px; }
.nav-title { font-size: 16px; }

.nav-links {
  display: flex;
  align-items: center;
  gap: 4px;
  list-style: none;
  margin: 0;
  padding: 0;
  flex: 1;
}

.nav-links li {
  padding: 7px 14px;
  border-radius: 9px;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--text-soft);
  cursor: pointer;
  transition: color .18s, background .18s;
  user-select: none;
}

.nav-links li:hover {
  color: var(--gold-soft);
  background: rgba(212, 175, 55, .10);
}

.nav-links li.active {
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .55));
  box-shadow: 0 4px 16px rgba(200, 16, 46, .35), inset 0 0 10px rgba(0, 0, 0, .25);
}

.nav-user {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 14px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
}

.uname {
  font-size: 13px;
  color: var(--text);
  letter-spacing: 1px;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.logout {
  padding: 6px 12px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.logout:hover {
  color: var(--gold-soft);
  border-color: var(--gold);
}

@media (max-width: 780px) {
  .navbar { flex-wrap: wrap; gap: 12px; padding: 12px 18px; }
  .nav-links { order: 3; width: 100%; overflow-x: auto; flex-wrap: nowrap; }
  .nav-user { margin-left: auto; }
  .uname { display: none; }
}
</style>
