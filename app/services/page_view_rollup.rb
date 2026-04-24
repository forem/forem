class PageViewRollup
  ATTRIBUTES_PRESERVED = %i[article_id viewable_id viewable_type created_at user_id region].freeze
  ATTRIBUTES_DESTROYED = %i[id domain path referrer updated_at user_agent counts_for_number_of_views
                            time_tracked_in_seconds].freeze

  class ViewAggregator
    Compact = Struct.new(:views, :article_id, :viewable_id, :viewable_type, :user_id, :region) do
      def to_h
        super.except(:views).merge({
                                     counts_for_number_of_views: views.sum(&:counts_for_number_of_views),
                                     time_tracked_in_seconds: views.sum(&:time_tracked_in_seconds)
                                   })
      end
    end

    def initialize
      @aggregator = Hash.new do |level1, group_key|
        level1[group_key] = Hash.new do |level2, user_id|
          level2[user_id] = []
        end
      end
    end

    def <<(view)
      group_key = [view.article_id, view.viewable_id, view.viewable_type, view.region]
      @aggregator[group_key][view.user_id] << view
    end

    def each
      @aggregator.each_pair do |group_key, grouped_by_user|
        grouped_by_user.each_pair do |user_id, views|
          next unless views.size > 1

          yield Compact.new(views, group_key[0], group_key[1], group_key[2], user_id, group_key[3])
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
    fixed_date = date.to_datetime.beginning_of_day

    (0..23).each do |hour|
      start_hour = fixed_date.change(hour: hour)
      end_hour = fixed_date.change(hour: hour + 1)
      rows = relation.where(user_id: nil, created_at: start_hour...end_hour)
      aggregate_into_groups(rows).each do |compacted_views|
        created << compact_records(start_hour, compacted_views)
      end
    end

    created
  end

  private

  def aggregate_into_groups(rows)
    aggregator = ViewAggregator.new
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
