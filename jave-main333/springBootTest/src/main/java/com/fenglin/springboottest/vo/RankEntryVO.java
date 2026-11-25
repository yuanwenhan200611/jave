package com.fenglin.springboottest.vo;

import com.fenglin.springboottest.entity.SectMember;
import com.fenglin.springboottest.util.RealmTier;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 宗门榜条目：兼容原 sect_member 的全部展示字段，另附玩家标记与修为。
 *
 * <p>NPC 弟子来自 sect_member 表；当前登录玩家由 UserProfile + 跨模块统计实时折算，
 * 不写库，因此每次进榜看到的都是最新修为/贡献。</p>
 */
@Data
public class RankEntryVO {

    private Long id;
    /** 展示用道号（玩家取 nickname，回落 username） */
    private String name;
    private String realm;
    /** 境界层次：一层~九层 / 初期~巅峰 / 小成~巅峰 / 一重~九重 */
    private String stage;
    /** 完整境界展示：如「炼虚小成」「魔尊九重」 */
    private String realmFull;
    private String title;
    private String hall;
    private Long power;
    private Long contribution;
    private String icon;
    private LocalDateTime createTime;

    /** 是否为当前登录玩家（前端据此高亮「本座」） */
    private boolean me;
    /** 玩家修为，NPC 为 null（用于战力折算说明） */
    private Long cultivation;
    /** 玩家登录名，仅 me=true 时有值 */
    private String username;

    /** 辈分层 key：disciple / trueDisciple / elder / supreme */
    private String tier;
    /** 辈分层中文标签：弟子境 / 真传境 / 长老境 / 至尊境 */
    private String tierLabel;
    /** 是否属于长老榜（长老境 + 至尊境） */
    private boolean elder;

    public static RankEntryVO from(SectMember m) {
        RankEntryVO vo = new RankEntryVO();
        vo.setId(m.getId());
        vo.setName(m.getName());
        vo.setRealm(m.getRealm());
        vo.setStage(m.getStage());
        vo.setRealmFull(RealmTier.fullRealm(m.getRealm(), m.getStage()));
        vo.setTitle(m.getTitle());
        vo.setHall(m.getHall());
        vo.setPower(m.getPower());
        vo.setContribution(m.getContribution());
        vo.setIcon(m.getIcon());
        vo.setCreateTime(m.getCreateTime());
        vo.setTier(RealmTier.tierOf(m.getRealm()));
        vo.setTierLabel(RealmTier.labelOf(m.getRealm()));
        vo.setElder(RealmTier.isElder(m.getRealm()));
        return vo;
    }
}
