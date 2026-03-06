module Admin
  class KeywordTrendsController < Admin::ApplicationController
    layout "admin"

    DEFAULT_MONTH_RANGE = 12
    MAX_MONTH_RANGE = 36

    def index
      @term = params[:term].to_s.strip
      @start_month, @end_month = selected_months
      return if @term.blank?

      @period_counts = period_counts
      @total_matches = @period_counts.values.sum
      @max_matches = @period_counts.values.max.to_i
    end

    private

    def selected_months
      default_end_month = Time.zone.today.beginning_of_month
      default_start_month = (default_end_month - (DEFAULT_MONTH_RANGE - 1).months).beginning_of_month
      start_month = parse_month(params[:start_month]) || default_start_month
      end_month = parse_month(params[:end_month]) || default_end_month
      start_month, end_month = [start_month, end_month].minmax
      capped_end_month = [end_month, start_month + (MAX_MONTH_RANGE - 1).months].min

      [start_month.beginning_of_month, capped_end_month.beginning_of_month]
    end

    def parse_month(value)
      return if value.blank?

      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      nil
    end

    def period_counts
      counts_by_month = Article.published
        .where.not(published_at: nil)
        .where(published_at: @start_month.beginning_of_day..@end_month.end_of_month.end_of_day)
        .where("reading_list_document @@ plainto_tsquery('english', ?)", @term)
        .group(Arel.sql("date_trunc('month', published_at)"))
        .order(Arel.sql("date_trunc('month', published_at)"))
        .count
        .transform_keys { |period| period.to_date.beginning_of_month }

      build_months.each_with_object({}) do |month, counts|
        counts[month] = counts_by_month.fetch(month, 0)
      end
    end

    def build_months
      month = @start_month
      months = []
      while month <= @end_month
        months << month
        month = month.next_month
      end
      months
    end
  end
end
