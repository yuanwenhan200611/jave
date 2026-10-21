<template>
  <aside class="brand">
    <div class="brand-watermark">魔</div>
    <div class="brand-mist"></div>

    <div class="logo">
      <span class="logo-mark">
        <svg viewBox="0 0 48 48" fill="none" stroke="#e8c66a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 4 40 14v20L24 44 8 34V14z" />
          <path d="M24 14 32 18v12l-8 4-8-4V18z" opacity=".7" />
          <circle cx="24" cy="24" r="3.4" fill="#e8c66a" stroke="none" />
        </svg>
      </span>
      <span class="logo-text">{{ title }}</span>
    </div>

    <div class="brand-copy">
      <div class="seal">逆</div>
      <h1>天命加身<br>逆道独行</h1>
      <p>九幽黄泉，皆入我掌心；<br>登临绝巅，执掌轮回。</p>
    </div>

    <div class="brand-foot">
      © 2026 逆天魔宗<br>
      堕魔者，永生不灭
    </div>
  </aside>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: '逆天魔宗'
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
  background:
    radial-gradient(130% 90% at 18% -10%, rgba(200, 16, 46, .5), transparent 58%),
    radial-gradient(120% 80% at 110% 120%, rgba(123, 15, 29, .55), transparent 55%),
    linear-gradient(155deg, #2a0710 0%, #4a0c18 38%, #160a18 100%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  overflow: hidden;
  border-right: 1px solid var(--border-strong);
}

/* 巨型水印「魔」字，营造墨气压境 */
.brand-watermark {
  position: absolute;
  right: -46px;
  bottom: -78px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 360px;
  line-height: 1;
  font-weight: 700;
  color: rgba(212, 175, 55, .06);
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
    radial-gradient(60% 40% at 80% 20%, rgba(255, 255, 255, .05), transparent 70%),
    radial-gradient(50% 35% at 20% 80%, rgba(255, 77, 94, .10), transparent 70%);
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

.seal {
  width: 64px;
  height: 64px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 38px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 2px solid var(--gold);
  box-shadow: 0 6px 22px rgba(200, 16, 46, .5), inset 0 0 12px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
  margin-bottom: 22px;
}

.brand-copy h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 34px;
  line-height: 1.4;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
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

  .brand-foot {
    display: none;
  }
}
</style>
