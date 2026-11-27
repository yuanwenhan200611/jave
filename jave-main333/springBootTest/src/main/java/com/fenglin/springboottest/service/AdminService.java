package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.AdminUser;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.mapper.AdminUserMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.mapper.UserProfileMapper;
import com.fenglin.springboottest.util.AdminSessionUtil;
import com.fenglin.springboottest.util.RealmTier;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 后台管理：管理员登录 + 洞府档案（user_profile）数据管理。
 * 只有后台接口走这里的会话校验，前台 /api/profile/** 保持原样。
 */
@Service
@RequiredArgsConstructor
public class AdminService {

    private static final Set<String> HALLS = Set.of(
            "主殿", "血煞堂", "幽冥堂", "千机堂", "执法堂", "炼丹堂");
    private static final int MAX_NICKNAME = 20;
    private static final int MAX_ICON = 8;
    private static final int MAX_BIO = 100;

    private final AdminUserMapper adminUserMapper;
    private final UserMapper userMapper;
    private final UserProfileMapper userProfileMapper;

    /** 管理员登录：账号 + MD5 密码，成功签发后台 token */
    public Map<String, Object> login(String username, String password) {
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            throw new IllegalArgumentException("请输入后台账号和密码");
        }
        AdminUser admin = adminUserMapper.selectOne(
                new LambdaQueryWrapper<AdminUser>().eq(AdminUser::getUsername, username.trim()));
        if (admin == null || !admin.getPassword().equals(DigestUtils.md5DigestAsHex(password.getBytes()))) {
            throw new IllegalArgumentException("后台账号或密码错误");
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("token", AdminSessionUtil.create(admin.getUsername()));
        data.put("adminUsername", admin.getUsername());
        data.put("displayName", admin.getDisplayName() == null ? "宗门执事" : admin.getDisplayName());
        return data;
    }

    public void logout(String token) {
        AdminSessionUtil.remove(token);
    }

    public Map<String, String> session(String token) {
        return AdminSessionUtil.session(token);
    }

    /** 洞府档案分页列表 + 概览统计（keyword 匹配账号或道号） */
    public Map<String, Object> profiles(String keyword, int page, int size) {
        LambdaQueryWrapper<UserProfile> wrapper = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isBlank()) {
            String kw = keyword.trim();
            wrapper.like(UserProfile::getUsername, kw).or().like(UserProfile::getNickname, kw);
        }
        wrapper.orderByDesc(UserProfile::getUpdateTime).orderByDesc(UserProfile::getId);

        List<UserProfile> all = userProfileMapper.selectList(wrapper);
        int pageNo = Math.max(1, page);
        int pageSize = Math.min(100, Math.max(1, size));
        int from = Math.min((pageNo - 1) * pageSize, all.size());
        int to = Math.min(from + pageSize, all.size());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", new ArrayList<>(all.subList(from, to)));
        data.put("total", all.size());
        data.put("page", pageNo);
        data.put("size", pageSize);
        data.put("summary", summary());
        return data;
    }

    private Map<String, Object> summary() {
        List<UserProfile> all = userProfileMapper.selectList(null);
        long totalCultivation = all.stream()
                .mapToLong(p -> p.getCultivation() == null ? 0L : p.getCultivation())
                .sum();
        Map<String, Integer> realmCounts = new LinkedHashMap<>();
        RealmTier.REALMS.forEach(realm -> realmCounts.put(realm, 0));
        all.forEach(p -> {
            String realm = p.getRealm();
            if (realm != null && realmCounts.containsKey(realm)) {
                realmCounts.put(realm, realmCounts.get(realm) + 1);
            }
        });

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("profileCount", all.size());
        summary.put("userCount", userMapper.selectCount(null));
        summary.put("totalCultivation", totalCultivation);
        summary.put("realmCounts", realmCounts);
        return summary;
    }

    /** 新增档案：用户必须已存在，且尚无档案 */
    public UserProfile create(Map<String, Object> body) {
        String username = text(body, "username", 50, true);
        if (!username.matches("^[A-Za-z0-9_]{3,20}$")) {
            throw new IllegalArgumentException("账号需为 3-20 位字母、数字或下划线");
        }
        Long userCount = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getUsername, username));
        if (userCount == null || userCount == 0) {
            throw new IllegalArgumentException("该用户不存在，请先在前台注册");
        }
        Long exists = userProfileMapper.selectCount(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, username));
        if (exists != null && exists > 0) {
            throw new IllegalArgumentException("该用户已有洞府档案，请直接编辑");
        }

        UserProfile profile = new UserProfile();
        profile.setUsername(username);
        applyFields(profile, body);
        if (profile.getNickname() == null) profile.setNickname(username);
        if (profile.getIcon() == null) profile.setIcon("🧙");
        if (profile.getRealm() == null) profile.setRealm("炼气");
        if (profile.getHall() == null) profile.setHall("血煞堂");
        if (profile.getBio() == null) profile.setBio("");
        if (profile.getCultivation() == null) profile.setCultivation(0L);
        userProfileMapper.insert(profile);
        return userProfileMapper.selectById(profile.getId());
    }

    /** 编辑档案：只更新传进来的字段 */
    public UserProfile update(String username, Map<String, Object> body) {
        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, username));
        if (profile == null) {
            throw new IllegalArgumentException("洞府档案不存在");
        }
        applyFields(profile, body);
        userProfileMapper.updateById(profile);
        return userProfileMapper.selectById(profile.getId());
    }

    /** 删除档案（只删档案，不删注册账号；下次进洞府会自动重建默认档案） */
    public void delete(String username) {
        userProfileMapper.delete(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, username));
    }

    private void applyFields(UserProfile profile, Map<String, Object> body) {
        if (body == null) return;

        String nickname = text(body, "nickname", MAX_NICKNAME, false);
        if (nickname != null) profile.setNickname(nickname);

        String icon = text(body, "icon", MAX_ICON, false);
        if (icon != null) profile.setIcon(icon);

        String realm = text(body, "realm", 10, false);
        if (realm != null) {
            if (!RealmTier.valid(realm)) {
                throw new IllegalArgumentException("境界不在十大境界之内");
            }
            profile.setRealm(realm);
        }

        String hall = text(body, "hall", 10, false);
        if (hall != null) {
            if (!HALLS.contains(hall)) {
                throw new IllegalArgumentException("堂口不存在");
            }
            profile.setHall(hall);
        }

        String bio = text(body, "bio", MAX_BIO, false);
        if (bio != null) profile.setBio(bio);

        Object cultivation = body.get("cultivation");
        if (cultivation != null && !String.valueOf(cultivation).isBlank()) {
            long value;
            try {
                value = Long.parseLong(String.valueOf(cultivation).trim());
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("修为必须是整数");
            }
            if (value < 0) {
                throw new IllegalArgumentException("修为不能为负数");
            }
            profile.setCultivation(value);
        }
    }

    /** 取字符串字段：trim + 长度校验，required 时不允许空 */
    private String text(Map<String, Object> body, String key, int max, boolean required) {
        Object raw = body.get(key);
        if (raw == null) {
            if (required) throw new IllegalArgumentException("缺少参数：" + key);
            return null;
        }
        String value = String.valueOf(raw).trim();
        if (value.isEmpty()) {
            if (required) throw new IllegalArgumentException("缺少参数：" + key);
            return null;
        }
        if (value.length() > max) {
            throw new IllegalArgumentException(key + " 不能超过 " + max + " 个字符");
        }
        return value;
    }
}
