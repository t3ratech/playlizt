/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 11:03
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.auth.entity;

import zw.co.t3ratech.playlizt.auth.model.PlayliztTab;
import zw.co.t3ratech.playlizt.auth.model.PlayliztTheme;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "playlizt_user_settings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlayliztUserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PlayliztTheme theme;

    @Enumerated(EnumType.STRING)
    @Column(name = "startup_tab", nullable = false, length = 50)
    private PlayliztTab startupTab;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "playlizt_user_visible_tabs", joinColumns = @JoinColumn(name = "settings_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "tab_id", length = 50)
    @Builder.Default
    private List<PlayliztTab> visibleTabs = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "playlizt_user_library_scan_folders", joinColumns = @JoinColumn(name = "settings_id"))
    @Column(name = "folder", columnDefinition = "TEXT")
    @Builder.Default
    private List<String> libraryScanFolders = new ArrayList<>();

    @Column(name = "download_directory", length = 500, nullable = false)
    private String downloadDirectory;

    @Column(name = "max_concurrent_downloads", nullable = false)
    private Integer maxConcurrentDownloads;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
