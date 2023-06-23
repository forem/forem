class DisplayAdEventRollup
  ATTRIBUTES_PRESERVED = %i[user_id display_ad_id category context_type created_at].freeze
  ATTRIBUTES_DESTROYED = %i[id counts_for updated_at].freeze

  class EventAggregator
    Compact = Struct.new(:events, :user_id, :display_ad_id, :category, :context_type) do
      def to_h
        super.except(:events).merge({ counts_for: events.sum(&:counts_for) })
      end
    end

    def initialize
      @aggregator = Hash.new do |level1, user_id|
        level1[user_id] = Hash.new do |level2, display_ad_id|
          level2[display_ad_id] = Hash.new do |level3, category|
            level3[category] = Hash.new do |level4, context_type|
              level4[context_type] = []
            end
          end
        end
      end
    end

    def <<(event)
      @aggregator[event.user_id][event.display_ad_id][event.category][event.context_type] << event
    end

    def each
      @aggregator.each_pair do |user_id, grouped_by_user_id|
        grouped_by_user_id.each_pair do |display_ad_id, grouped_by_display_ad_id|
          grouped_by_display_ad_id.each_pair do |category, grouped_by_category|
            grouped_by_category.each_pair do |context_type, events|
              next unless events.size > 1

              yield Compact.new(events, user_id, display_ad_id, category, context_type)
            end
          end
        end
      end
    end

    private

    attr_reader :aggregator
  end

  def self.rollup(date, relation: DisplayAdEvent)
    new(relation: relation).rollup(date)
  end

  def initialize(relation:)
    @aggregator = EventAggregator.new
    @relation = relation
  end

  attr_reader :aggregator, :relation

  def rollup(date)
    created = []

    rows = relation.where(created_at: date.all_day)
    aggregate_into_groups(rows).each do |compacted_events|
      created << compact_records(date, compacted_events)
    end

    created
  end

  private

  def aggregate_into_groups(rows)
    rows.in_batches.each_record do |event|
      aggregator << event
    end

    aggregator
  end

  def compact_records(date, compacted)
    result = nil

    relation.transaction do
      result = relation.create!(compacted.to_h) do |event|
        event.created_at = date
      end

      relation.where(id: compacted.events).delete_all
    end

    result
  end
end
