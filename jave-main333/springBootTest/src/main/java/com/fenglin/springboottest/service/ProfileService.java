package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.entity.SearchLog;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.mapper.ForumPostMapper;
import com.fenglin.springboottest.mapper.SearchLogMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.mapper.UserProfileMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 洞府（个人页）服务：档案读取 / 保存，以及跨模块联动数据聚合。
 *
 * 联动关系：
 *   · 论道 forum_post —— 以 author = username 统计发帖数、获赞数、我的帖子列表
 *   · 首页 search_log —— 以 username 统计搜索次数、最近搜索足迹
 *   · 用户 user       —— 入宗时间（注册时间）
 */
@Service
@RequiredArgsConstructor
public class ProfileService {

    private static final Set<String> REALMS = Set.of(
            "炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫", "魔尊");
    private static final Set<String> HALLS = Set.of(
            "主殿", "血煞堂", "幽冥堂", "千机堂", "执法堂", "炼丹堂");
    private static final int MAX_NICKNAME = 20;
    private static final int MAX_BIO = 100;
    private static final int MAX_ICON = 8;
    private static final int MAX_LIST = 20;

    private final UserMapper userMapper;
    private final UserProfileMapper userProfileMapper;
    private final ForumPostMapper forumPostMapper;
    private final SearchLogMapper searchLogMapper;

    /**
     * 读取个人档案（不存在则自动创建默认档案）+ 跨模块统计。
     * 返回：{ profile, user:{ username, createdAt }, stats:{ postCount, likeCount, searchCount } }
     */
    public Map<String, Object> getProfile(String username) {
        String name = requireUsername(username);

        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>().eq(User::getUsername, name));
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, name));
        if (profile == null) {
            profile = createDefaultProfile(name);
        }

        // 跨模块统计：论道发帖 / 获赞 / 首页搜索
        Long postCount = forumPostMapper.selectCount(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1));
        List<ForumPost> myPosts = forumPostMapper.selectList(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1)
                        .orderByDesc(ForumPost::getCreateTime)
                        .orderByDesc(ForumPost::getId)
                        .last("LIMIT " + MAX_LIST));
        long likeCount = myPosts.stream()
                .mapToLong(p -> p.getLikes() == null ? 0L : p.getLikes())
                .sum();

        Long searchCount = searchLogMapper.selectCount(
                new LambdaQueryWrapper<SearchLog>().eq(SearchLog::getUsername, name));

        Map<String, Object> stats = new HashMap<>();
        stats.put("postCount", postCount == null ? 0L : postCount);
        stats.put("likeCount", likeCount);
        stats.put("searchCount", searchCount == null ? 0L : searchCount);

        Map<String, Object> userBrief = new HashMap<>();
        userBrief.put("username", user.getUsername());
        userBrief.put("createdAt", user.getCreateTime());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("profile", profile);
        data.put("user", userBrief);
        data.put("stats", stats);
        return data;
    }

    /**
     * 保存个人档案（upsert）：道号 / 头像 / 境界 / 堂口 / 签名。
     */
    public UserProfile updateProfile(String username, String nickname, String icon,
                                     String realm, String hall, String bio) {
        String name = requireUsername(username);

        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, name));
        if (profile == null) {
            profile = createDefaultProfile(name);
        }

        String nick = normalize(nickname, null, MAX_NICKNAME);
        if (nick != null) {
            profile.setNickname(nick);
        }
        String ic = normalize(icon, null, MAX_ICON);
        if (ic != null) {
            profile.setIcon(ic);
        }
        String r = normalize(realm, null, 10);
        if (r != null) {
            if (!REALMS.contains(r)) {
                throw new IllegalArgumentException("境界不在十大境界之内");
            }
            profile.setRealm(r);
        }
        String h = normalize(hall, null, 10);
        if (h != null) {
            if (!HALLS.contains(h)) {
                throw new IllegalArgumentException("堂口不存在");
            }
            profile.setHall(h);
        }
        String b = normalize(bio, "", MAX_BIO);
        if (b != null) {
            profile.setBio(b);
        }

        userProfileMapper.updateById(profile);
        // 回读，拿到数据库 ON UPDATE 维护的 update_time
        return userProfileMapper.selectById(profile.getId());
    }

    /**
     * 我的帖子（论道联动）：最近 20 条，时间倒序。
     */
    public List<ForumPost> myPosts(String username) {
        String name = requireUsername(username);
        List<ForumPost> list = forumPostMapper.selectList(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1)
                        .orderByDesc(ForumPost::getCreateTime)
                        .orderByDesc(ForumPost::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /**
     * 搜索足迹（首页联动）：最近 20 条搜索记录，时间倒序。
     */
    public List<SearchLog> mySearches(String username) {
        String name = requireUsername(username);
        List<SearchLog> list = searchLogMapper.selectList(
                new LambdaQueryWrapper<SearchLog>().eq(SearchLog::getUsername, name)
                        .orderByDesc(SearchLog::getCreateTime)
                        .orderByDesc(SearchLog::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /** 首次进入洞府：生成一份默认档案 */
    private UserProfile createDefaultProfile(String username) {
        UserProfile profile = new UserProfile();
        profile.setUsername(username);
        profile.setNickname(username);
        // 单个码位的 emoji，避免组合 emoji（如 🧑‍🦲）在部分字体下拆成两个字形溢出头像框
        profile.setIcon("🧙");
        profile.setRealm("炼气");
        profile.setHall("血煞堂");
        profile.setBio("初入魔宗，道心未定。");
        userProfileMapper.insert(profile);
        return userProfileMapper.selectById(profile.getId());
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }

    /** 去空白 + 截断；null 原样返回 null（表示不修改该字段） */
    private String normalize(String s, String emptyFallback, int max) {
        if (s == null) {
            return null;
        }
        String v = s.trim();
        if (v.isEmpty()) {
            return emptyFallback;
        }
        return v.length() > max ? v.substring(0, max) : v;
    }
}
