/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.playback.repository;

import zw.co.t3ratech.playlizt.playback.entity.ViewingHistory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ViewingHistoryRepository extends JpaRepository<ViewingHistory, Long> {
    
    Optional<ViewingHistory> findByUserIdAndContentId(Long userId, Long contentId);
    
    Page<ViewingHistory> findByUserId(Long userId, Pageable pageable);
    
    @Query("SELECT vh FROM ViewingHistory vh WHERE vh.userId = :userId AND vh.completed = false AND vh.lastPositionSeconds > 0 ORDER BY vh.updatedAt DESC")
    Page<ViewingHistory> findContinueWatching(@Param("userId") Long userId, Pageable pageable);
    
    @Query("SELECT COUNT(DISTINCT vh.userId) FROM ViewingHistory vh WHERE vh.contentId = :contentId")
    Long countUniqueViewersByContentId(@Param("contentId") Long contentId);
    
    @Query("SELECT SUM(vh.watchTimeSeconds) FROM ViewingHistory vh WHERE vh.contentId = :contentId")
    Long sumWatchTimeByContentId(@Param("contentId") Long contentId);
    
    @Query("SELECT SUM(vh.watchTimeSeconds) FROM ViewingHistory vh")
    Long sumTotalWatchTime();
}
