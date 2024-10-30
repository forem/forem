class BillboardEventRollup
  ATTRIBUTES_PRESERVED = %i[user_id display_ad_id category context_type created_at].freeze
  ATTRIBUTES_DESTROYED = %i[id counts_for updated_at article_id geolocation].freeze
  STATEMENT_TIMEOUT = ENV.fetch("STATEMENT_TIMEOUT_BULK_DELETE", 10_000).to_i.seconds / 1_000.to_f

  class EventAggregator
    Compact = Struct.new(:events, :user_id, :display_ad_id, :category, :context_type) do
      def to_h
        {
          user_id: user_id,
          display_ad_id: display_ad_id,
          category: category,
          context_type: context_type,
          counts_for: events.sum(&:counts_for),
          created_at: events.first.created_at
        }
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
      @aggregator.each_pair do |user_id, grouped_by_user|
        grouped_by_user.each_pair do |display_ad_id, grouped_by_display_ad|
          grouped_by_display_ad.each_pair do |category, grouped_by_category|
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

  def self.rollup(date, relation: BillboardEvent)
    new(relation: relation).rollup(date)
  end

  def initialize(relation:)
    @relation = relation
  end

  attr_reader :relation

  def rollup(date, batch_size: 1000)
    created = []
    # Set statement_timeout for the initial query and then reset it
    relation.connection.execute("SET statement_timeout = '#{STATEMENT_TIMEOUT}s'")
    display_ad_ids = relation.where(created_at: date.all_day).distinct.pluck(:display_ad_id)
    relation.connection.execute("RESET statement_timeout")
  
    display_ad_ids.each do |display_ad_id|
      aggregator = EventAggregator.new
  
      # Each billboard is processed in its own transaction
      relation.transaction(requires_new: true) do
        relation.connection.execute("SET LOCAL statement_timeout = '#{STATEMENT_TIMEOUT}s'")
  
        relation.where(display_ad_id: display_ad_id, created_at: date.all_day).in_batches(of: batch_size) do |batch|
          batch.each do |event|
            aggregator << event
          end
        end
  
        aggregator.each do |compacted_events|
          created << compact_records(compacted_events)
        end
      ensure
        relation.connection.execute("RESET statement_timeout")
      end
    end
  
    created
  end

  private

  def compact_records(compacted)
    result = nil

    relation.transaction do
      relation.connection.execute("SET LOCAL statement_timeout = '#{STATEMENT_TIMEOUT}s'")

      result = relation.create!(compacted.to_h)

      relation.where(id: compacted.events.map(&:id)).delete_all
    ensure
      relation.connection.execute("RESET statement_timeout")
    end

    result
  end
end
