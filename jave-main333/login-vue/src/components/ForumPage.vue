<template>
  <div class="page">
    <div class="page-bg" aria-hidden="true"></div>

    <SectNav active="forum" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 堂名 -->
    <header class="hero">
      <span class="hero-seal">论</span>
      <div>
        <h1>论道</h1>
        <p class="hero-desc">以道会友，以理服人 · 辱道友者，罚扫藏经阁</p>
      </div>
    </header>

    <!-- 操作条 -->
    <section class="ops">
      <div class="sort-bar">
        <button
          v-for="s in sortOptions"
          :key="s.value"
          type="button"
          class="sort-btn"
          :class="{ active: sort === s.value }"
          @click="changeSort(s.value)"
        >{{ s.label }}</button>
      </div>
      <button class="compose-btn" type="button" @click="openCompose">执 笔 开 帖</button>
    </section>

    <!-- 发帖面板 -->
    <section v-if="composing" class="compose">
      <div class="compose-head">
        <h2>开 帖 论 道</h2>
        <button class="detail-close" type="button" @click="composing = false">✕</button>
      </div>
      <input
        v-model.trim="form.title"
        class="compose-title"
        type="text"
        maxlength="100"
        placeholder="帖名（1-100 字）"
      >
      <textarea
        v-model.trim="form.content"
        class="compose-content"
        rows="5"
        maxlength="2000"
        placeholder="正文（1-2000 字，讲道陈情，言之有物）"
      ></textarea>
      <div class="compose-foot">
        <span class="compose-note">落款：{{ username }}</span>
        <button class="compose-submit" type="button" :disabled="submitting" @click="submit">
          {{ submitting ? '发 布 中……' : '发 布' }}
        </button>
      </div>
    </section>

    <!-- 帖子列表 -->
    <section class="posts-wrap">
      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!loading && !posts.length" class="empty">论道堂空空如也，且做开坛第一人</p>

      <ul v-else class="post-list">
        <li v-for="p in posts" :key="p.id" class="post-card">
          <div class="post-head">
            <span class="post-avatar">{{ p.author?.slice(0, 1) || '道' }}</span>
            <div class="post-who">
              <h3>{{ p.title }}</h3>
              <p class="post-meta">{{ p.author }} · {{ fmtTime(p.createTime) }} · {{ p.views }} 围观</p>
            </div>
            <button class="like-btn" :class="{ liked: likedIds.has(p.id) }" type="button" @click="onLike(p)">
              道 <b>{{ p.likes }}</b>
            </button>
          </div>
          <p class="post-body">{{ p.content }}</p>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 论道 · 一言既出，驷马难追</footer>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { createPost, fetchPosts, likePost } from '../api/forum'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const sort = ref('new')
const sortOptions = [
  { value: 'new', label: '最新' },
  { value: 'hot', label: '热议' }
]

const loading = ref(false)
const error = ref('')
const posts = ref([])
const page = ref(1)
const pageSize = 10
const pages = ref(0)

// 发帖
const composing = ref(false)
const submitting = ref(false)
const form = ref({ title: '', content: '' })

// 已点赞集合（本次会话内，防连点刷赞）
const likedIds = ref(new Set())

onMounted(load)

async function load(toPage = 1) {
  loading.value = true
  error.value = ''
  try {
    const data = await fetchPosts({ sort: sort.value, page: toPage, size: pageSize })
    posts.value = data.list || []
    pages.value = data.pages || 0
    page.value = data.page || toPage
  } catch (e) {
    error.value = e.message || '论道加载失败'
  } finally {
    loading.value = false
  }
}

function changeSort(s) {
  if (sort.value === s) return
  sort.value = s
  load(1)
}

function gotoPage(p) {
  if (p < 1 || p > pages.value || p === page.value) return
  load(p)
}

function openCompose() {
  composing.value = true
  form.value = { title: '', content: '' }
}

async function submit() {
  if (!form.value.title) {
    showToast('帖名不可为空')
    return
  }
  if (!form.value.content) {
    showToast('正文不可为空')
    return
  }
  submitting.value = true
  try {
    await createPost({
      author: props.username || '道友',
      title: form.value.title,
      content: form.value.content
    })
    showToast('开帖成功，道音已传遍宗门')
    composing.value = false
    await load(1)
  } catch (e) {
    showToast(e.message || '发布失败')
  } finally {
    submitting.value = false
  }
}

async function onLike(post) {
  if (likedIds.value.has(post.id)) {
    showToast('道心相印一次足矣')
    return
  }
  try {
    const res = await likePost(post.id)
    post.likes = res.likes
    likedIds.value.add(post.id)
  } catch (e) {
    showToast(e.message || '点赞失败')
  }
}

function fmtTime(s) {
  if (!s) return '不详'
  return String(s).replace('T', ' ').slice(0, 16)
}
</script>

<style scoped>
.page {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  background: var(--card);
  border: 1px solid var(--border-strong);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .10),
    0 30px 80px rgba(0, 0, 0, .65),
    0 0 60px rgba(200, 16, 46, .18);
  backdrop-filter: blur(6px);
}

.page-bg {
  position: absolute;
  inset: -8%;
  z-index: 0;
  background-image: url('../assets/home-bg.jpg');
  background-size: cover;
  background-position: center;
  filter: blur(30px) brightness(.30) saturate(1.1);
}

.page > :not(.page-bg) {
  position: relative;
  z-index: 1;
}

/* ===== 堂名 ===== */
.hero {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 34px 32px 22px;
}

.hero-seal {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 30px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 2px solid var(--gold);
  box-shadow: 0 4px 18px rgba(200, 16, 46, .5), inset 0 0 10px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
  flex-shrink: 0;
}

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
  margin: 0;
}

.hero-desc {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .75);
  margin: 6px 0 0;
}

/* ===== 操作条 ===== */
.ops {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 32px 16px;
}

.sort-bar { display: flex; gap: 6px; }

.sort-btn {
  padding: 4px 14px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .5);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.sort-btn:hover { color: var(--gold-soft); border-color: var(--gold); }

.sort-btn.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
  box-shadow: 0 0 12px rgba(200, 16, 46, .3);
}

.compose-btn {
  padding: 8px 24px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 55%, #e23a4e 100%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 3px;
  box-shadow: 0 4px 18px rgba(200, 16, 46, .4), inset 0 0 10px rgba(0, 0, 0, .3);
  transition: transform .15s, filter .2s;
  flex-shrink: 0;
}

.compose-btn:hover { transform: translateY(-1px); filter: brightness(1.12); }

/* ===== 发帖面板 ===== */
.compose {
  margin: 0 32px 18px;
  padding: 18px 20px;
  border: 1px solid var(--gold);
  border-radius: 14px;
  background: rgba(12, 8, 18, .85);
  box-shadow: 0 0 24px rgba(200, 16, 46, .2);
}

.compose-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.compose-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 17px;
  letter-spacing: 4px;
  color: var(--gold-soft);
  margin: 0;
}

.detail-close {
  width: 28px;
  height: 28px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: transparent;
  color: var(--text-soft);
  cursor: pointer;
  font-family: inherit;
}

.detail-close:hover { color: var(--gold-soft); border-color: var(--gold); }

.compose-title {
  width: 100%;
  height: 40px;
  margin-bottom: 10px;
  padding: 0 12px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: var(--card-input);
  color: var(--text);
  font-family: inherit;
  font-size: 14px;
  outline: none;
}

.compose-title:focus,
.compose-content:focus { border-color: var(--gold); }

.compose-content {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: var(--card-input);
  color: var(--text);
  font-family: inherit;
  font-size: 14px;
  line-height: 1.8;
  resize: vertical;
  outline: none;
}

.compose-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 10px;
}

.compose-note { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; }

.compose-submit {
  padding: 8px 26px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 60%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 3px;
}

.compose-submit:disabled { opacity: .7; cursor: wait; }

/* ===== 帖子列表 ===== */
.posts-wrap { padding: 0 32px 24px; }

.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 22px 0;
}

.post-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.post-card {
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .72);
  transition: border-color .18s, background .18s;
}

.post-card:hover { border-color: var(--gold); background: rgba(28, 18, 36, .65); }

.post-head {
  display: flex;
  align-items: center;
  gap: 12px;
}

.post-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 15px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
  flex-shrink: 0;
}

.post-who { flex: 1; min-width: 0; }

.post-who h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 3px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.post-meta { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; margin: 0; }

.like-btn {
  padding: 6px 14px;
  border: 1px solid var(--border-strong);
  border-radius: 999px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
  flex-shrink: 0;
}

.like-btn b { color: inherit; margin-left: 4px; }

.like-btn:hover { color: var(--gold-soft); border-color: var(--gold); }

.like-btn.liked {
  color: #f7e9c4;
  border-color: rgba(226, 58, 78, .7);
  background: linear-gradient(135deg, rgba(140, 15, 29, .6), rgba(200, 16, 46, .4));
  box-shadow: 0 0 10px rgba(200, 16, 46, .35);
}

.post-body {
  margin: 12px 0 0;
  font-size: 13px;
  line-height: 1.9;
  color: var(--text-soft);
  white-space: pre-wrap;
  word-break: break-word;
}

/* ===== 分页 ===== */
.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  margin-top: 14px;
}

.pager-btn {
  padding: 5px 16px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.pager-btn:hover:not(:disabled) { color: var(--gold-soft); border-color: var(--gold); }
.pager-btn:disabled { opacity: .4; cursor: not-allowed; }

.pager-info { font-size: 12px; color: var(--text-soft); letter-spacing: 1px; }

/* ===== 页脚 / 响应式 ===== */
.page-foot {
  padding: 16px 32px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

@media (max-width: 780px) {
  .hero { padding: 26px 18px 18px; }
  .hero h1 { font-size: 21px; letter-spacing: 2px; }
  .ops { flex-wrap: wrap; padding: 0 18px 14px; }
  .compose { margin: 0 18px 16px; }
  .posts-wrap { padding: 0 18px 20px; }
  .post-meta { display: none; }
}
</style>
