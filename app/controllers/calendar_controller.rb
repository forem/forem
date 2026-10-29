class CalendarController < ApplicationController
  EVENTS_PER_PAGE = 12
  VALID_YEAR_RANGE = (2000..2100)
  AGENDA_COLUMNS = %i[
    id title type_of start_time end_time event_name_slug event_variation_slug
    delegate_to_page page_id organization_id user_id
  ].freeze
  private_constant :AGENDA_COLUMNS

  def index
    @range_start, @range_end = calendar_range
    # The displayed month is driven by its own param so paging through months
    # with the nav arrows never clobbers the user's selected start/end range.
    @display_month = display_month
    @grid_start = @display_month.beginning_of_week(:sunday)
    @grid_end = @display_month.end_of_month.end_of_week(:sunday)

    @event_day_set = event_days_between(@grid_start, @grid_end)

    if range_has_events?
      agenda = published_events.where("end_time >= ? AND start_time <= ?",
                                      @range_start.beginning_of_day, @range_end.end_of_day)
      @events = agenda.order(start_time: :asc).page(params[:page]).per(EVENTS_PER_PAGE)
      @events_by_day = @events.group_by { |event| event.start_time.to_date }
    else
      @events = Event.none.page(params[:page]).per(EVENTS_PER_PAGE)
      @events_by_day = {}
    end
    @user_signup_event_ids = signed_up_event_ids
  end

  private

  def published_events
    events = Event.published.select(AGENDA_COLUMNS).includes(:page, :organization, :user)
    events = events.where(type_of: params[:type_of]) if valid_type?
    events
  end

  def range_has_events?
    return true if @range_start < @grid_start || @range_end > @grid_end
    return false if @event_day_set.empty?

    (@range_start..@range_end).any? { |day| @event_day_set.include?(day) }
  end

  # Every day within the grid window that a published event covers (a multi-day
  # event dots each day it spans). The card itself shows the full start–end range.
  def event_days_between(range_start, range_end)
    scope = Event.published
    scope = scope.where(type_of: params[:type_of]) if valid_type?
    event_days = Set.new
    scope.where("end_time >= ? AND start_time <= ?",
                range_start.beginning_of_day, range_end.end_of_day)
      .pluck(:start_time, :end_time)
      .each do |start_time, end_time|
        start_date = [start_time.in_time_zone.to_date, range_start].max
        end_date = [end_time.in_time_zone.to_date, range_end].min
        (start_date..end_date).each { |day| event_days.add(day) }
      end
    event_days
  end

  def calendar_range
    start_date = parse_date(params[:start])
    end_date = parse_date(params[:end])
    @explicit_range = start_date.present? || end_date.present?

    if start_date.nil? && end_date.nil?
      today = Time.zone.today
      return [today.beginning_of_month, today.end_of_month]
    end

    start_date ||= end_date
    end_date ||= start_date
    start_date, end_date = end_date, start_date if end_date < start_date
    [start_date, end_date]
  end

  def parse_date(value)
    return if value.blank?

    date = Date.iso8601(value)
    date if VALID_YEAR_RANGE.cover?(date.year)
  rescue ArgumentError, TypeError
    nil
  end

  # The month shown in the grid; falls back to the selected range's month so a
  # fresh visit (or one with no month param) still lands on the right page.
  def display_month
    parse_month(params[:month]) || @range_start.beginning_of_month
  end

  def parse_month(value)
    return if value.blank?

    date = Date.strptime(value, "%Y-%m").beginning_of_month
    date if VALID_YEAR_RANGE.cover?(date.year)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_type?
    params[:type_of].present? && Event.type_ofs.key?(params[:type_of])
  end

  def signed_up_event_ids
    return Set.new unless user_signed_in? && @events_by_day.any?

    EventSignup.where(user: current_user, event: @events.map(&:id)).pluck(:event_id).to_set
  end
end
