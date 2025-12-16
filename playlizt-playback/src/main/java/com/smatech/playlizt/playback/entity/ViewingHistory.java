/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.playback.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "viewing_history", indexes = {
    @Index(name = "idx_viewing_user", columnList = "user_id"),
    @Index(name = "idx_viewing_content", columnList = "content_id"),
    @Index(name = "idx_viewing_updated", columnList = "updated_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ViewingHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, name = "user_id")
    private Long userId;

    @Column(nullable = false, name = "content_id")
    private Long contentId;

    @Column(name = "watch_time_seconds", nullable = false)
    private Integer watchTimeSeconds = 0;

    @Column(name = "last_position_seconds", nullable = false)
    private Integer lastPositionSeconds = 0;

    @Column(nullable = false)
    private Boolean completed = false;

    @CreationTimestamp
    @Column(nullable = false, updatable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}
