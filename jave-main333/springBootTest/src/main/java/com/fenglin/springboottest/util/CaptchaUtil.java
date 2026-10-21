package com.fenglin.springboottest.util;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.Base64;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 图形验证码工具：
 * 1. 生成随机 4 位验证码图片，返回 base64 给前端展示
 * 2. 验证码答案存在内存 Map 中（captchaId -> code），5 分钟有效
 * 3. 校验时忽略大小写，且一次性使用（校验后立即删除）
 *
 * 说明：内存存储适用于单机演示；集群部署建议换成 Redis。
 */
public class CaptchaUtil {

    /** 验证码有效期：5 分钟 */
    private static final long EXPIRE_MS = 5 * 60 * 1000L;

    /** 去掉易混淆的 0/O、1/I/l */
    private static final String CHARS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

    private static final Map<String, Entry> STORE = new ConcurrentHashMap<>();

    private record Entry(String code, long expireAt) {
    }

    /** 生成验证码：返回 [captchaId, base64Image] */
    public static String[] create() {
        // 顺手清理过期条目
        long now = System.currentTimeMillis();
        STORE.entrySet().removeIf(e -> e.getValue().expireAt() < now);

        String code = randomCode(4);
        String captchaId = UUID.randomUUID().toString();
        STORE.put(captchaId, new Entry(code, now + EXPIRE_MS));
        return new String[]{captchaId, "data:image/png;base64," + drawImage(code)};
    }

    /** 校验验证码（忽略大小写、一次性），返回 null 表示通过，否则返回错误提示 */
    public static String verify(String captchaId, String input) {
        if (captchaId == null || input == null || input.isBlank()) {
            return "请输入验证码";
        }
        Entry entry = STORE.remove(captchaId); // 无论对错都删除，防止重复尝试
        if (entry == null || System.currentTimeMillis() > entry.expireAt()) {
            return "验证码已过期，请刷新后重试";
        }
        if (!entry.code().equalsIgnoreCase(input.trim())) {
            return "验证码不正确";
        }
        return null; // 通过
    }

    private static String randomCode(int len) {
        Random r = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < len; i++) {
            sb.append(CHARS.charAt(r.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    /** 用 AWT 绘制验证码图片并编码为 base64 */
    private static String drawImage(String code) {
        int width = 112, height = 46;
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        Random r = new Random();

        try {
            // 背景
            g.setColor(new Color(240, 241, 255));
            g.fillRect(0, 0, width, height);

            // 干扰线
            for (int i = 0; i < 4; i++) {
                g.setColor(new Color(120 + r.nextInt(100), 120 + r.nextInt(100), 160 + r.nextInt(60)));
                g.setStroke(new BasicStroke(1f));
                g.drawLine(r.nextInt(width), r.nextInt(height), r.nextInt(width), r.nextInt(height));
            }

            // 逐字符绘制：随机颜色 + 旋转 + 上下偏移
            char[] chars = code.toCharArray();
            for (int i = 0; i < chars.length; i++) {
                g.setColor(new Color(30 + r.nextInt(110), 30 + r.nextInt(110), 120 + r.nextInt(100)));
                g.setFont(new Font("Georgia", Font.BOLD, 22 + r.nextInt(6)));
                double theta = (r.nextDouble() - 0.5) * 0.5;
                int x = 16 + i * 24;
                int y = height / 2 + (r.nextInt(9) - 4);
                g.rotate(theta, x, y);
                g.drawChars(chars, i, 1, x, y);
                g.rotate(-theta, x, y);
            }

            // 噪点
            for (int i = 0; i < 26; i++) {
                g.setColor(new Color(100 + r.nextInt(120), 100 + r.nextInt(120), 100 + r.nextInt(120)));
                g.fillRect(r.nextInt(width), r.nextInt(height), 2, 2);
            }
        } finally {
            g.dispose();
        }

        try (ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            ImageIO.write(img, "png", bos);
            return Base64.getEncoder().encodeToString(bos.toByteArray());
        } catch (Exception e) {
            throw new RuntimeException("生成验证码图片失败", e);
        }
    }
}
