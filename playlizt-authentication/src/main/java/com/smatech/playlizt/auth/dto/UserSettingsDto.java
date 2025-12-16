/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 11:09
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.auth.dto;

import zw.co.t3ratech.playlizt.auth.model.PlayliztTab;
import zw.co.t3ratech.playlizt.auth.model.PlayliztTheme;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSettingsDto {

	private PlayliztTheme theme;
	private PlayliztTab startupTab;
	private List<PlayliztTab> visibleTabs;
	private String downloadDirectory;
	private List<String> libraryScanFolders;
	private Integer maxConcurrentDownloads;
}
