<template>
  <div class="admin-page">
    <header class="admin-nav">
      <div class="admin-brand">
        <span class="admin-mark">寂</span>
        <span>寂幽门 · 执事台</span>
        <span class="tag">后台管理</span>
      </div>
      <div class="admin-user">
        <span>{{ adminName }}</span>
        <button type="button" @click="emit('back')">返回宗门</button>
        <button type="button" class="danger" @click="handleLogout">退出后台</button>
      </div>
    </header>

    <section class="admin-hero">
      <div>
        <h1>洞府数据管理</h1>
        <p>管理首页「修行速览」与洞府页展示的会员档案：道号、头像、境界、修为、堂口与道语。</p>
      </div>
    </section>

    <section class="stat-grid">
      <div class="stat-card">
        <span class="stat-label">洞府档案</span>
        <b>{{ summary.profileCount ?? 0 }}</b>
        <small>份会员档案</small>
      </div>
      <div class="stat-card">
        <span class="stat-label">注册会员</span>
        <b>{{ summary.userCount ?? 0 }}</b>
        <small>前台账号</small>
      </div>
      <div class="stat-card">
        <span class="stat-label">修为总量</span>
        <b>{{ formatNumber(summary.totalCultivation || 0) }}</b>
        <small>全宗累计修为</small>
      </div>
      <div class="stat-card">
        <span class="stat-label">当前境界分布</span>
        <b class="realm-line">{{ topRealms }}</b>
        <small>人数最多的三个境界</small>
      </div>
    </section>

    <section class="panel">
      <div class="toolbar">
        <input v-model="keyword" type="text" placeholder="搜索账号或道号" @keyup.enter="reload">
        <button type="button" @click="reload">搜 索</button>
        <button type="button" class="primary" @click="openCreate">＋ 新增档案</button>
        <span v-if="loading" class="loading-hint">读取中…</span>
      </div>

      <p v-if="error" class="error-line" role="alert">{{ error }}</p>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>账号</th>
              <th>道号</th>
              <th>头像</th>
              <th>境界</th>
              <th>修为</th>
              <th>堂口</th>
              <th>更新时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in rows" :key="row.id">
              <td class="mono">{{ row.username }}</td>
              <td>{{ row.nickname }}</td>
              <td class="icon-cell">{{ row.icon || '—' }}</td>
              <td>{{ fullRealm(row.realm, stageOf(row.realm, row.cultivation || 0)) }}</td>
              <td class="mono">{{ formatNumber(row.cultivation || 0) }}</td>
              <td>{{ row.hall }}</td>
              <td class="dim">{{ formatTime(row.updateTime) }}</td>
              <td class="ops">
                <button type="button" @click="openEdit(row)">编辑</button>
                <button type="button" class="danger" @click="remove(row)">删除</button>
              </td>
            </tr>
            <tr v-if="!loading && !rows.length">
              <td colspan="8" class="empty">暂无洞府档案，换个关键词或新增一份</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" :disabled="page <= 1" @click="changePage(-1)">上一页</button>
        <span>第 {{ page }} / {{ totalPages }} 页 · 共 {{ total }} 条</span>
        <button type="button" :disabled="page >= totalPages" @click="changePage(1)">下一页</button>
      </div>
    </section>

    <div v-if="dialog" class="modal-mask" @click.self="closeDialog">
      <form class="modal" @submit.prevent="save">
        <h2>{{ editing ? '编辑洞府档案' : '新增洞府档案' }}</h2>
        <p class="modal-sub">{{ editing ? '修改后会同步到首页修行速览与洞府页。' : '为已注册会员创建一份洞府档案。' }}</p>

        <label>
          <span>账号</span>
          <input v-model.trim="form.username" :disabled="editing" placeholder="已注册的前台账号" maxlength="50">
        </label>
        <label>
          <span>道号</span>
          <input v-model.trim="form.nickname" placeholder="展示昵称" maxlength="20">
        </label>
        <div class="form-row">
          <label>
            <span>头像</span>
            <input v-model.trim="form.icon" placeholder="🧙" maxlength="8">
          </label>
          <label>
            <span>境界</span>
            <select v-model="form.realm">
              <option v-for="realm in REALMS" :key="realm" :value="realm">{{ realm }}</option>
            </select>
          </label>
        </div>
        <div class="form-row">
          <label>
            <span>修为</span>
            <input v-model.trim="form.cultivation" type="number" min="0" step="1" placeholder="0">
          </label>
          <label>
            <span>堂口</span>
            <select v-model="form.hall">
              <option v-for="hall in HALLS" :key="hall" :value="hall">{{ hall }}</option>
            </select>
          </label>
        </div>
        <label>
          <span>道语</span>
          <textarea v-model.trim="form.bio" rows="3" maxlength="100" placeholder="一句话签名"></textarea>
        </label>

        <p v-if="formError" class="form-error" role="alert">{{ formError }}</p>

        <div class="modal-ops">
          <button type="button" @click="closeDialog">取消</button>
          <button type="submit" class="primary" :disabled="saving">{{ saving ? '保存中…' : '保存' }}</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useToast } from '../composables/useToast'
import { REALMS, fullRealm, stageOf } from '../utils/realm'
import {
  fetchAdminProfiles, createAdminProfile, updateAdminProfile, deleteAdminProfile, adminLogout
} from '../api/admin'

const props = defineProps({
  adminName: { type: String, default: '宗门执事' }
})
const emit = defineEmits(['back', 'logout'])
const { showToast } = useToast()

const HALLS = ['主殿', '血煞堂', '幽冥堂', '千机堂', '执法堂', '炼丹堂']

const rows = ref([])
const total = ref(0)
const page = ref(1)
const size = 10
const keyword = ref('')
const loading = ref(false)
const error = ref('')
const summary = ref({})

const dialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const formError = ref('')
const form = reactive({
  username: '', nickname: '', icon: '', realm: '炼气', cultivation: 0, hall: '血煞堂', bio: ''
})

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / size)))
const topRealms = computed(() => {
  const counts = summary.value.realmCounts || {}
  return Object.entries(counts)
    .filter(([, count]) => count > 0)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([realm, count]) => `${realm} ${count}`)
    .join(' · ') || '—'
})

function formatNumber(value) {
  return Number(value || 0).toLocaleString('zh-CN')
}

function formatTime(value) {
  if (!value) return '—'
  return String(value).replace('T', ' ').slice(0, 16)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const data = await fetchAdminProfiles({ keyword: keyword.value, page: page.value, size })
    rows.value = data.list || []
    total.value = data.total || 0
    summary.value = data.summary || {}
    if (page.value > totalPages.value) {
      page.value = totalPages.value
      await load()
    }
  } catch (err) {
    error.value = err.message || '数据加载失败'
    if (error.value.includes('登录')) emit('logout')
  } finally {
    loading.value = false
  }
}

function reload() {
  page.value = 1
  load()
}

function changePage(step) {
  const next = page.value + step
  if (next < 1 || next > totalPages.value) return
  page.value = next
  load()
}

function openCreate() {
  editing.value = false
  formError.value = ''
  Object.assign(form, {
    username: '', nickname: '', icon: '🧙', realm: '炼气', cultivation: 0, hall: '血煞堂', bio: ''
  })
  dialog.value = true
}

function openEdit(row) {
  editing.value = true
  formError.value = ''
  Object.assign(form, {
    username: row.username,
    nickname: row.nickname || '',
    icon: row.icon || '',
    realm: row.realm || '炼气',
    cultivation: row.cultivation || 0,
    hall: row.hall || '血煞堂',
    bio: row.bio || ''
  })
  dialog.value = true
}

function closeDialog() {
  dialog.value = false
}

async function save() {
  formError.value = ''
  if (!form.username) {
    formError.value = '请输入账号'
    return
  }
  saving.value = true
  try {
    const payload = {
      nickname: form.nickname,
      icon: form.icon,
      realm: form.realm,
      cultivation: form.cultivation,
      hall: form.hall,
      bio: form.bio
    }
    if (editing.value) {
      await updateAdminProfile(form.username, payload)
      showToast('洞府档案已更新')
    } else {
      await createAdminProfile({ username: form.username, ...payload })
      showToast('洞府档案已创建')
    }
    dialog.value = false
    load()
  } catch (err) {
    formError.value = err.message || '保存失败'
    if (formError.value.includes('登录')) emit('logout')
  } finally {
    saving.value = false
  }
}

async function remove(row) {
  if (!window.confirm(`确定删除 ${row.username} 的洞府档案吗？\n（不会删除前台账号，下次进洞府会自动重建默认档案）`)) return
  try {
    await deleteAdminProfile(row.username)
    showToast('档案已删除')
    load()
  } catch (err) {
    error.value = err.message || '删除失败'
  }
}

async function handleLogout() {
  try {
    await adminLogout()
  } catch {
    // 本地 token 已清，后端退出失败也不影响离开后台
  }
  emit('logout')
}

onMounted(load)
</script>

<style scoped>
.admin-page {
  max-width: 1320px;
  margin: 0 auto;
  padding: 18px 28px 48px;
}

.admin-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border);
}

.admin-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 2px;
  color: var(--gold-soft);
}

.admin-mark {
  width: 32px;
  height: 32px;
  display: grid;
  place-items: center;
  border: 1px solid var(--gold);
  border-radius: 9px;
  background: linear-gradient(145deg, #3b215e, #8c0f1d);
}

.tag {
  padding: 2px 8px;
  border: 1px solid rgba(185, 164, 242, .4);
  border-radius: 20px;
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 1px;
  color: var(--violet-soft);
}

.admin-user {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--text-soft);
}

.admin-user button,
.toolbar button,
.pager button,
.ops button,
.modal-ops button {
  padding: 7px 14px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.admin-user button:hover,
.toolbar button:hover,
.pager button:hover,
.ops button:hover,
.modal-ops button:hover {
  color: var(--gold-soft);
  border-color: var(--gold);
}

button.primary {
  border-color: rgba(212, 175, 55, .6);
  background: linear-gradient(135deg, #8c0f1d, #c8102e);
  color: #f7e9c4;
}

button.danger:hover {
  color: var(--danger);
  border-color: var(--danger);
}

button:disabled {
  opacity: .45;
  cursor: not-allowed;
}

.admin-hero {
  margin: 26px 0 20px;
}

.admin-hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 28px;
  letter-spacing: 4px;
  color: var(--gold-soft);
}

.admin-hero p {
  margin-top: 8px;
  font-size: 13px;
  color: var(--text-soft);
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
  margin-bottom: 18px;
}

.stat-card {
  padding: 16px 18px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(14, 9, 20, .8);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
}

.stat-card b {
  font-size: 24px;
  color: var(--gold-soft);
}

.stat-card b.realm-line {
  font-size: 15px;
  line-height: 1.6;
}

.stat-card small {
  font-size: 11px;
  color: var(--text-dim);
}

.panel {
  padding: 18px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(14, 9, 20, .86);
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 14px;
}

.toolbar input {
  width: 260px;
  height: 36px;
  padding: 0 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--card-input);
  color: var(--text);
  font: inherit;
  font-size: 13px;
  outline: none;
}

.toolbar input:focus { border-color: var(--gold); }
.loading-hint { font-size: 12px; color: var(--text-dim); }
.error-line { margin-bottom: 12px; font-size: 12px; color: var(--danger); }

.table-wrap { overflow-x: auto; }

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

th, td {
  padding: 11px 10px;
  text-align: left;
  border-bottom: 1px solid rgba(196, 154, 92, .14);
  white-space: nowrap;
}

th {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-dim);
  letter-spacing: 1px;
}

td { color: var(--text); }
td.mono { font-family: Consolas, Monaco, monospace; font-size: 12px; }
td.icon-cell { font-size: 18px; }
td.dim { color: var(--text-dim); font-size: 12px; }
td.empty { text-align: center; color: var(--text-dim); padding: 30px 10px; }

.ops { display: flex; gap: 8px; }
.ops button { padding: 5px 10px; font-size: 12px; }

.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 16px;
  font-size: 12px;
  color: var(--text-soft);
}

.modal-mask {
  position: fixed;
  inset: 0;
  z-index: 20;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(4, 2, 8, .72);
}

.modal {
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  padding: 26px 28px;
  border: 1px solid rgba(212, 175, 55, .4);
  border-radius: 16px;
  background: #16101e;
  box-shadow: 0 24px 60px rgba(0, 0, 0, .65);
}

.modal h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 21px;
  letter-spacing: 3px;
  color: var(--gold-soft);
}

.modal-sub {
  margin: 6px 0 18px;
  font-size: 12px;
  color: var(--text-dim);
}

.modal label {
  display: block;
  margin-bottom: 14px;
  font-size: 12px;
  color: var(--text-soft);
}

.modal label span {
  display: block;
  margin-bottom: 6px;
}

.modal input,
.modal select,
.modal textarea {
  width: 100%;
  padding: 9px 11px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--card-input);
  color: var(--text);
  font: inherit;
  font-size: 13px;
  outline: none;
}

.modal input:focus,
.modal select:focus,
.modal textarea:focus { border-color: var(--gold); }
.modal input:disabled { opacity: .55; }

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-error {
  margin: 4px 0 12px;
  font-size: 12px;
  color: var(--danger);
}

.modal-ops {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 6px;
}

@media (max-width: 900px) {
  .stat-grid { grid-template-columns: repeat(2, 1fr); }
  .admin-page { padding: 18px 16px 40px; }
}

@media (max-width: 600px) {
  .stat-grid { grid-template-columns: 1fr; }
  .toolbar { flex-wrap: wrap; }
  .toolbar input { width: 100%; }
  .form-row { grid-template-columns: 1fr; }
}
</style>
