/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 10:29
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.auth.repository;

import zw.co.t3ratech.playlizt.auth.entity.PlayliztUserSettings;
import zw.co.t3ratech.playlizt.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PlayliztUserSettingsRepository extends JpaRepository<PlayliztUserSettings, Long> {

    Optional<PlayliztUserSettings> findByUser(User user);
}
