ActsAsTaggableOn.force_lowercase = true
ActsAsTaggableOn.strict_case_match = true

# Pre-acquire row-level locks on affected tags in deterministic ascending ID
# order before destroying or creating taggings. Each Tagging create/destroy
# updates `tags.taggings_count` via counter_cache (`FOR NO KEY UPDATE`), so
# concurrent saves with overlapping tags in different user-specified orders
# would otherwise lock `tags` rows in opposite orders and deadlock.
module ActsAsTaggableOnOrderedTagLocks
  # Persists taggings for all tagging contexts while pre-locking affected tags
  # in ascending ID order to prevent counter-cache deadlocks.
  def save_tags
    tagging_contexts.each do |context|
      next unless tag_list_cache_set_on(context)

      tag_list = tag_list_cache_on(context).uniq
      tags = find_or_create_tags_from_list_with_context(tag_list, context)
      current_tags = tags_on(context)

      old_tags, new_tags = resolve_tag_changes(current_tags, tags)
      lock_affected_tags_in_order(old_tags, new_tags)

      taggings.not_owned.by_context(context).where(tag_id: old_tags).order(:tag_id).destroy_all if old_tags.present?

      new_tags.each do |tag|
        if taggable_tenant
          taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self, tenant: taggable_tenant)
        else
          taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self)
        end
      end
    end

    true
  end

  private

  # Computes [old_tags, new_tags] to remove and add for the current context,
  # accounting for tag ordering when preserve_tag_order? is enabled.
  def resolve_tag_changes(current_tags, tags)
    old_tags = current_tags - tags
    new_tags = tags - current_tags
    return [old_tags, new_tags] unless self.class.preserve_tag_order?

    shared_tags = current_tags & tags
    if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
      index = shared_tags.each_with_index do |_, i|
        break i unless shared_tags[i] == tags[i]
      end

      old_tags |= current_tags[index...current_tags.size]
      new_tags |= current_tags[index...current_tags.size] & shared_tags

      new_tags = tags.filter_map do |t|
        new_tags.detect { |n| n.name.casecmp?(t.name) }
      end
    end

    [old_tags, new_tags]
  end

  # Pre-acquires FOR NO KEY UPDATE locks on all affected tags in ascending ID
  # order when two or more tags will have their taggings_count updated.
  def lock_affected_tags_in_order(old_tags, new_tags)
    return unless ActsAsTaggableOn.tags_counter

    affected_tag_ids = (old_tags + new_tags).filter_map(&:id).uniq.sort
    return unless affected_tag_ids.size > 1

    ActsAsTaggableOn::Tag.where(id: affected_tag_ids).order(:id).lock("FOR NO KEY UPDATE").ids
  end
end

ActsAsTaggableOn::Taggable::Core.prepend(ActsAsTaggableOnOrderedTagLocks)
