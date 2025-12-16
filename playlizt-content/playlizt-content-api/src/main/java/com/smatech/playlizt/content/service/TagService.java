/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.content.service;

import zw.co.t3ratech.playlizt.content.entity.Tag;
import zw.co.t3ratech.playlizt.content.repository.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TagService {

    private final TagRepository tagRepository;

    public List<Tag> getAllTags() {
        return tagRepository.findAll();
    }

    public Tag getTag(Long id) {
        return tagRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Tag not found"));
    }

    @Transactional
    public Tag createTag(Tag tag) {
        if (tagRepository.existsByName(tag.getName())) {
            throw new IllegalArgumentException("Tag already exists");
        }
        return tagRepository.save(tag);
    }

    @Transactional
    public Tag updateTag(Long id, Tag tagDetails) {
        Tag tag = getTag(id);
        tag.setName(tagDetails.getName());
        return tagRepository.save(tag);
    }

    @Transactional
    public void deleteTag(Long id) {
        tagRepository.deleteById(id);
    }
}
