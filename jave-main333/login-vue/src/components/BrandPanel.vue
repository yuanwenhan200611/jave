<template>
  <aside class="brand">
    <div class="brand-watermark">寂</div>
    <div class="brand-mist"></div>
    <div class="brand-motes" aria-hidden="true">
      <span v-for="mote in motes" :key="mote.id" :style="moteStyle(mote)"></span>
    </div>
    <div class="brand-runes" aria-hidden="true">幽 门 夜 启 · 万 籁 归 寂</div>

    <div class="logo">
      <span class="logo-mark">
        <svg viewBox="0 0 48 48" fill="none" stroke="#e8c66a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 42V17l16-10 16 10v25" />
          <path d="M15 42V23l9-6 9 6v19" opacity=".65" />
          <path d="M20 42V31h8v11" opacity=".45" />
          <circle cx="24" cy="26" r="2.2" fill="#e8c66a" stroke="none" />
        </svg>
      </span>
      <span class="logo-text">{{ title }}</span>
    </div>

    <div class="brand-copy">
      <div class="seal-wrap">
        <div class="seal-halo"></div>
        <div class="seal">寂</div>
      </div>
      <h1>幽门夜启<br>寂影独行</h1>
      <p>万籁归寂，幽影随行；<br>一入此门，生死由心。</p>
    </div>

    <div class="brand-foot">
      © 2026 寂幽门<br>
      寂夜长明，幽影不灭
    </div>
  </aside>
</template>

<script setup>
// 幽火浮尘：位置/大小/延迟用确定性公式生成，避免每次渲染跳动
const motes = Array.from({ length: 14 }, (_, i) => ({
  id: i,
  left: `${(i * 37 + 11) % 94}%`,
  top: `${(i * 61 + 9) % 90}%`,
  size: 2 + (i % 3) * 1.6,
  delay: -((i % 7) * 1.1),
  duration: 7 + (i % 5) * 1.3
}))

function moteStyle(mote) {
  return {
    left: mote.left,
    top: mote.top,
    width: `${mote.size}px`,
    height: `${mote.size}px`,
    animationDelay: `${mote.delay}s`,
    animationDuration: `${mote.duration}s`
  }
}

defineProps({
  title: {
    type: String,
    default: '寂幽门'
  },
  supportEmail: {
    type: String,
    default: 'support@workbuddy.cn'
  }
})
</script>

<style scoped>
.brand {
  position: relative;
  padding: 56px 48px;
  color: var(--text);
  /* 血雾里掺一缕幽紫：保留魔修气质，又贴住「寂幽门」的夜色 */
  background:
    radial-gradient(110% 80% at 8% -12%, rgba(139, 107, 214, .20), transparent 62%),
    radial-gradient(120% 90% at 15% 10%, rgba(200, 16, 46, .20), transparent 62%),
    radial-gradient(120% 80% at 110% 120%, rgba(123, 15, 29, .26), transparent 58%),
    linear-gradient(155deg, rgba(24, 10, 32, .44) 0%, rgba(56, 10, 20, .30) 40%, rgba(12, 8, 24, .52) 100%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  overflow: hidden;
  border-right: 1px solid var(--border-strong);
}

/* 内嵌细框：像门匾的描边，压住大面积渐变的散感 */
.brand::after {
  content: "";
  position: absolute;
  inset: 14px;
  border: 1px solid rgba(212, 175, 55, .12);
  border-radius: 14px;
  pointer-events: none;
  z-index: 0;
}

/* 巨型水印「寂」字，营造墨气压境 */
.brand-watermark {
  position: absolute;
  right: -46px;
  bottom: -78px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 360px;
  line-height: 1;
  font-weight: 700;
  color: rgba(185, 164, 242, .08);
  pointer-events: none;
  user-select: none;
  z-index: 0;
}

/* 煞气流雾 */
.brand-mist {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 0;
  background:
    radial-gradient(60% 40% at 80% 20%, rgba(185, 164, 242, .09), transparent 70%),
    radial-gradient(50% 35% at 20% 80%, rgba(255, 77, 94, .10), transparent 70%);
  animation: mist-drift 14s ease-in-out infinite alternate;
}

@keyframes mist-drift {
  from { transform: translate3d(-6px, 0, 0); opacity: .75; }
  to   { transform: translate3d(8px, -10px, 0); opacity: 1; }
}

/* 幽火浮尘 */
.brand-motes {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: 0;
}

.brand-motes span {
  position: absolute;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(240, 232, 255, .95) 0%, rgba(185, 164, 242, .55) 45%, rgba(139, 107, 214, 0) 75%);
  box-shadow: 0 0 10px rgba(185, 164, 242, .55);
  animation-name: mote-float;
  animation-timing-function: ease-in-out;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}

@keyframes mote-float {
  from { transform: translate3d(0, 8px, 0); opacity: .2; }
  to   { transform: translate3d(6px, -16px, 0); opacity: .85; }
}

/* 门匾侧边的竖排小字 */
.brand-runes {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  writing-mode: vertical-rl;
  text-orientation: upright;
  letter-spacing: 6px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 12px;
  color: rgba(212, 175, 55, .20);
  pointer-events: none;
  user-select: none;
  z-index: 1;
}

@media (prefers-reduced-motion: reduce) {
  .brand-mist,
  .brand-motes span,
  .seal-halo { animation: none; }
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 19px;
  font-weight: 700;
  letter-spacing: 3px;
  position: relative;
  z-index: 1;
  color: var(--gold-soft);
}

.logo-mark {
  width: 38px;
  height: 38px;
  border-radius: 11px;
  background: rgba(0, 0, 0, .35);
  border: 1px solid rgba(212, 175, 55, .55);
  display: grid;
  place-items: center;
  box-shadow: 0 0 18px rgba(212, 175, 55, .25);
}

.logo-mark svg {
  width: 22px;
  height: 22px;
}

.brand-copy {
  position: relative;
  z-index: 1;
  margin-top: 40px;
}

.brand-copy::before {
  content: "";
  position: absolute;
  left: -60px;
  top: -40px;
  width: 260px;
  height: 260px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(139, 107, 214, .16), transparent 70%);
  pointer-events: none;
  z-index: -1;
}

/* 印章外包一层呼吸的幽光环，像门中透出的夜气 */
.seal-wrap {
  position: relative;
  width: 104px;
  height: 104px;
  display: grid;
  place-items: center;
  margin: 0 0 16px -18px;
}

.seal-halo {
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  border: 1px solid rgba(185, 164, 242, .28);
  box-shadow: 0 0 26px rgba(139, 107, 214, .22), inset 0 0 22px rgba(139, 107, 214, .12);
  animation: halo-breathe 5s ease-in-out infinite alternate;
}

.seal-halo::after {
  content: "";
  position: absolute;
  inset: 8px;
  border-radius: 50%;
  border: 1px dashed rgba(212, 175, 55, .22);
}

@keyframes halo-breathe {
  from { transform: scale(.94); opacity: .6; }
  to   { transform: scale(1.04); opacity: 1; }
}

.seal {
  position: relative;
  z-index: 1;
  width: 64px;
  height: 64px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 38px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #3b215e 0%, #8c0f1d 55%, #c8102e 100%);
  border: 2px solid var(--gold);
  box-shadow: 0 6px 22px rgba(139, 107, 214, .28), 0 6px 22px rgba(200, 16, 46, .42), inset 0 0 12px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
}

.brand-copy h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 34px;
  line-height: 1.4;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45), 0 0 26px rgba(139, 107, 214, .25);
}

.brand-copy p {
  margin-top: 16px;
  font-size: 14px;
  line-height: 2;
  color: rgba(236, 230, 245, .72);
  letter-spacing: 1px;
}

.brand-foot {
  position: relative;
  z-index: 1;
  font-size: 12px;
  color: rgba(212, 175, 55, .55);
  line-height: 1.9;
  letter-spacing: 1px;
}

@media (max-width: 780px) {
  .brand {
    padding: 36px 32px;
  }

  .brand-copy {
    margin-top: 24px;
  }

  .brand-copy h1 {
    font-size: 26px;
  }

  .brand-watermark {
    font-size: 240px;
    right: -30px;
    bottom: -50px;
  }

  .brand-runes {
    display: none;
  }

  .seal-wrap {
    margin-bottom: 12px;
    transform: scale(.86);
    transform-origin: left center;
  }

  .brand-foot {
    display: none;
  }
}
</style>
