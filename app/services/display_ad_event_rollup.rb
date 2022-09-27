class DisplayAdEventRollup
  def self.rollup(date, relation: DisplayAdEvent)
    new(relation: relation).rollup(date)
  end

  def initialize(relation:)
    @relation = relation
  end

  attr_reader :relation

  def rollup(date)
    created = []

    rows = relation.where(created_at: date.all_day)
    aggregate_into_groups(rows)

    grouped_by.each_pair do |user_id, grouped_by_user_id|
      grouped_by_user_id.each_pair do |display_ad_id, grouped_by_display_ad_id|
        grouped_by_display_ad_id.each_pair do |category, grouped_by_category|
          grouped_by_category.each_pair do |context_type, events|
            next unless events.size > 1

            created << compact_event_records(date,
                                             events,
                                             user_id: user_id,
                                             display_ad_id: display_ad_id,
                                             category: category,
                                             context_type: context_type)
          end
        end
      end
    end

    created
  end

  private

  def aggregate_into_groups(rows)
    rows.in_batches.each_record do |event|
      grouped_by[event.user_id][event.display_ad_id][event.category][event.context_type] << event
    end
  end

  def compact_event_records(date, events, user_id:, display_ad_id:, category:, context_type:)
    result = nil
    counts_for = events.sum(&:counts_for)

    relation.transaction do
      result = relation.create!(user_id: user_id,
                                display_ad_id: display_ad_id,
                                category: category,
                                context_type: context_type,
                                counts_for: counts_for) do |event|
                                  event.created_at = date
                                end

      relation.where(id: events).delete_all
    end

    result
  end

  def grouped_by
    @grouped_by ||= Hash.new do |level1, user_id|
      level1[user_id] = Hash.new do |level2, display_ad_id|
        level2[display_ad_id] = Hash.new do |level3, category|
          level3[category] = Hash.new do |level4, context_type|
            level4[context_type] = []
          end
        end
      end
    end
  end
end
