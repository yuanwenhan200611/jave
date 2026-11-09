package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.mapper.ForumPostMapper;
import com.fenglin.springboottest.vo.PageResult;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 论道服务：帖子分页列表 / 发帖 / 点赞（道心相印）。
 */
@Service
public class ForumService {

    private static final long DEFAULT_PAGE_SIZE = 10L;
    private static final long MAX_PAGE_SIZE = 50L;
    private static final int MAX_TITLE_LENGTH = 100;
    private static final int MAX_CONTENT_LENGTH = 2000;
    private static final int MAX_AUTHOR_LENGTH = 50;

    private final ForumPostMapper forumPostMapper;

    public ForumService(ForumPostMapper forumPostMapper) {
        this.forumPostMapper = forumPostMapper;
    }

    /**
     * 帖子分页列表。
     *
     * @param sort new（默认，按发帖时间倒序）/ hot（按点赞数倒序）
     */
    public PageResult<ForumPost> page(String sort, Integer pageNo, Integer pageSize) {
        long p = pageNo == null || pageNo < 1 ? 1 : pageNo;
        long s = pageSize == null || pageSize < 1 ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);

        boolean byHot = "hot".equalsIgnoreCase(sort);
        LambdaQueryWrapper<ForumPost> qw = new LambdaQueryWrapper<ForumPost>()
                .eq(ForumPost::getStatus, 1)
                .orderByDesc(ForumPost::getCreateTime)
                .orderByDesc(ForumPost::getId);
        if (byHot) {
            // 热议：道心相印优先，时间兜底
            qw = new LambdaQueryWrapper<ForumPost>()
                    .eq(ForumPost::getStatus, 1)
                    .orderByDesc(ForumPost::getLikes)
                    .orderByDesc(ForumPost::getCreateTime);
        }

        Long totalObj = forumPostMapper.selectCount(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getStatus, 1));
        long total = totalObj == null ? 0L : totalObj;

        java.util.List<ForumPost> list = new java.util.ArrayList<>();
        if (total > 0) {
            long offset = (p - 1) * s;
            if (offset < total) {
                list = forumPostMapper.selectList(qw.last("LIMIT " + s + " OFFSET " + offset));
            }
        }
        return PageResult.of(list, total, p, s);
    }

    /**
     * 发帖。作者 / 帖名 / 正文做长度与空值校验。
     */
    public ForumPost create(String author, String title, String content) {
        String a = normalize(author, "道友", MAX_AUTHOR_LENGTH);
        String t = normalize(title, null, MAX_TITLE_LENGTH);
        String c = normalize(content, null, MAX_CONTENT_LENGTH);
        if (t == null) {
            throw new IllegalArgumentException("帖名不能为空");
        }
        if (c == null) {
            throw new IllegalArgumentException("正文不能为空");
        }

        ForumPost post = new ForumPost();
        post.setAuthor(a);
        post.setTitle(t);
        post.setContent(c);
        post.setViews(0L);
        post.setLikes(0L);
        post.setStatus(1);
        post.setCreateTime(LocalDateTime.now());
        forumPostMapper.insert(post);
        return post;
    }

    /**
     * 道心相印（点赞）+1，返回最新点赞数。
     */
    public long like(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("帖子 id 不能为空");
        }
        ForumPost post = forumPostMapper.selectById(id);
        if (post == null || post.getStatus() == null || post.getStatus() != 1) {
            throw new IllegalArgumentException("帖子不存在或已被封禁");
        }
        forumPostMapper.update(null, new UpdateWrapper<ForumPost>()
                .setSql("likes = likes + 1")
                .eq("id", id));
        return (post.getLikes() == null ? 0L : post.getLikes()) + 1;
    }

    /** 去空白 + 截断；blank 时返回 fallback（可为 null） */
    private String normalize(String s, String fallback, int max) {
        if (s == null) {
            return fallback;
        }
        String v = s.trim();
        if (v.isEmpty()) {
            return fallback;
        }
        return v.length() > max ? v.substring(0, max) : v;
    }
}
