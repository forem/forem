class PageViewRollup
  ATTRIBUTES_PRESERVED = %i[article_id page_id created_at user_id].freeze
  ATTRIBUTES_DESTROYED = %i[id domain path referrer updated_at user_agent counts_for_number_of_views
                            time_tracked_in_seconds].freeze

  class ViewAggregator
    Compact = Struct.new(:views, :key, :key_value, :user_id) do
      def to_h
        {
          key => key_value,
          :user_id => user_id,
          :counts_for_number_of_views => views.sum(&:counts_for_number_of_views),
          :time_tracked_in_seconds => views.sum(&:time_tracked_in_seconds)
        }
      end
    end

    def initialize(key)
      @key = key
      @aggregator = Hash.new do |level1, key_value|
        level1[key_value] = Hash.new do |level2, user_id|
          level2[user_id] = []
        end
      end
    end

    def <<(view)
      @aggregator[view.public_send(@key)][view.user_id] << view
    end

    def each
      @aggregator.each_pair do |key_value, grouped_by_key|
        grouped_by_key.each_pair do |user_id, views|
          next unless views.size > 1

          yield Compact.new(views, @key, key_value, user_id)
        end
      end
    end

    private

    attr_reader :aggregator
  end

  def self.rollup(date, relation: PageView)
    new(relation: relation).rollup(date)
  end

  def initialize(relation:)
    @relation = relation
  end

  attr_reader :relation

  def rollup(date)
    created = []

    %i[article_id page_id].each do |key|
      fixed_date = date.to_datetime.beginning_of_day

      (0..23).each do |hour|
        start_hour = fixed_date.change(hour: hour)
        end_hour = fixed_date.change(hour: hour + 1)
        rows = relation.where.not(key => nil).where(user_id: nil, created_at: start_hour...end_hour)
        aggregate_into_groups(rows, key).each do |compacted_views|
          created << compact_records(start_hour, compacted_views)
        end
      end
    end

    created
  end

  private

  def aggregate_into_groups(rows, key)
    aggregator = ViewAggregator.new(key)
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

      relation.where(id: compacted.views).delete_all
    end

    result
  end
end
