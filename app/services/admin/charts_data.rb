module Admin
  class ChartsData
    def initialize(length = 7)
      @length = length
    end

    def call
      period = create_period(@length + 1, 1)
      previous_period = create_period(@length * 2, @length + 1)

      [
        { label: "Posts", model: Article, time_column: :published_at },
        { label: "Comments", model: Comment, time_column: :created_at },
        { label: "Reactions", model: Reaction, time_column: :created_at },
        { label: "New members", model: User, time_column: :registered_at },
      ].map { |dataset| build_data(dataset[:label], dataset[:model], dataset[:time_column], period, previous_period) }
    end

    private

    def create_period(start_days_ago, end_days_ago)
      start_days_ago.days.ago..end_days_ago.days.ago
    end

    def build_data(label, model, time_column, period, previous_period)
      grouped_data = model.where(time_column => period).group("DATE(#{time_column})").size
      previous_period_count = model.where(time_column => previous_period).size

      values = extract_values(grouped_data)

      [label, values.sum, previous_period_count, values]
    end

    def extract_values(grouped_data)
      @length.downto(1).map { |n| grouped_data[n.days.ago.to_date] || 0 }
    end
  end
end
