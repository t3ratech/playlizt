/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.content.repository;

import zw.co.t3ratech.playlizt.content.entity.Content;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;

@Repository
public interface ContentRepository extends JpaRepository<Content, Long>, JpaSpecificationExecutor<Content> {
    
    Page<Content> findByIsPublishedTrue(Pageable pageable);
    
    @Modifying
    @Query("UPDATE Content c SET c.viewCount = c.viewCount + 1 WHERE c.id = :id")
    void incrementViewCount(@Param("id") Long id);
    
    Page<Content> findByCreatorId(Long creatorId, Pageable pageable);
    
    Page<Content> findByCategory(String category, Pageable pageable);
    
    @Query("SELECT c FROM Content c WHERE c.isPublished = true AND " +
           "(LOWER(c.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(c.description) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Content> searchContent(@Param("query") String query, Pageable pageable);
    
    @Query("SELECT DISTINCT c.category FROM Content c WHERE c.isPublished = true ORDER BY c.category")
    List<String> findAllCategories();
    
    Optional<Content> findByIdAndIsPublishedTrue(Long id);
    
    @Query("SELECT c FROM Content c WHERE c.isPublished = true ORDER BY c.viewCount DESC")
    Page<Content> findPopularContent(Pageable pageable);
}
