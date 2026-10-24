module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, inverse_of: :reactable, dependent: :destroy
    has_many :distinct_reaction_categories, -> { order(:category).merge(Reaction.distinct_categories) },
             as: :reactable,
             inverse_of: :reactable,
             dependent: nil,
             class_name: "Reaction"
  end

  class_methods do
    # Batch sync reaction counts for multiple records efficiently
    # Uses transaction + row locking to prevent race conditions
    # Eliminates N+1 queries by using a single grouped query + batch update
    #
    # @param records [Array<ActiveRecord::Base>] records to sync
    # @return [Integer] number of records updated
    def sync_reactions_count_for_batch(records)
      return 0 if records.empty?

      ids = records.map(&:id)

      transaction do
        # Lock the rows to prevent concurrent updates (SKIP LOCKED for non-blocking)
        where(id: ids).lock("FOR UPDATE SKIP LOCKED").load

        # Single grouped query to get correct counts for all records
        correct_counts = Reaction
          .where(reactable_type: name, reactable_id: ids)
          .public_category
          .group(:reactable_id)
          .count

        # Use Arel for safe SQL generation instead of string interpolation
        update_cases = ids.map do |record_id|
          count = correct_counts[record_id] || 0
          Arel.sql("WHEN #{connection.quote(record_id)} THEN #{count.to_i}")
        end

        # Perform batch update using ActiveRecord with sanitized Arel
        where(id: ids).update_all(
          Arel.sql(
            "public_reactions_count = CASE id #{update_cases.join(' ')} END",
          ),
        )
      end

      ids.size
    end

    # Warm #public_reaction_categories for a list of records with one cache
    # round-trip (fetch_multi) instead of one cache.get per record.
    # Misses are computed and written exactly as the per-record fetch would.
    #
    # @param records [Array<ActiveRecord::Base>]
    def preload_reaction_counts_for_reactable(records)
      records_by_key = records.index_by(&:reaction_counts_cache_key)
      return if records_by_key.empty?

      counts_by_key = Rails.cache.fetch_multi(*records_by_key.keys, expires_in: 10.hours) do |key|
        records_by_key[key].send(:compute_reaction_counts_for_reactable)
      end
      records_by_key.each do |key, record|
        record.instance_variable_set(:@preloaded_reaction_counts_for_reactable, counts_by_key[key])
      end
    end
  end

  def reaction_counts_cache_key
    "reaction_counts_for_reactable-#{self.class.name}-#{id}"
  end

  def sync_reactions_count
    # Use transaction + row locking to prevent race conditions
    self.class.transaction do
      self.class.where(id: id).lock("FOR UPDATE").load
      correct_count = reactions.public_category.count
      self.class.where(id: id).update_all(public_reactions_count: correct_count)
    end
  end

  # Thread-safe sync that can be called from background jobs
  def sync_reactions_count!
    sync_reactions_count
    reload
  end

  def public_reaction_categories
    # Get reaction counts for this reactable
    reaction_counts = reaction_counts_for_reactable

    # Filter to only public reaction categories that have reactions
    categories_with_counts = reaction_counts.select do |count_data|
      category_slug = count_data[:category]
      count_data[:count].positive? && ReactionCategory[category_slug]&.visible_to_public?
    end

    # Sort by count (descending), then by position for ties, and limit to 3
    sorted_categories = categories_with_counts
      .sort_by { |count_data| [-count_data[:count], ReactionCategory[count_data[:category]]&.position || 99] }
      .first(3)

    # Convert back to ReactionCategory objects
    sorted_categories.map do |count_data|
      ReactionCategory[count_data[:category]]
    end
  end

  private

  def reaction_counts_for_reactable
    return [] unless respond_to?(:id)
    return @preloaded_reaction_counts_for_reactable if defined?(@preloaded_reaction_counts_for_reactable)

    Rails.cache.fetch(reaction_counts_cache_key, expires_in: 10.hours) do
      compute_reaction_counts_for_reactable
    end
  end

  def compute_reaction_counts_for_reactable
    reactions.group(:category).count.map do |category, count|
      { category: category, count: count }
    end
  end
end
