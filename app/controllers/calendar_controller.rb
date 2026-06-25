class CalendarController < ApplicationController
  EVENTS_PER_PAGE = 12

  def index
    @range_start, @range_end = calendar_range
    # The displayed month is driven by its own param so paging through months
    # with the nav arrows never clobbers the user's selected start/end range.
    @display_month = display_month
    @grid_start = @display_month.beginning_of_week(:sunday)
    @grid_end = @display_month.end_of_month.end_of_week(:sunday)

    @event_day_set = event_days_between(@grid_start, @grid_end)

    agenda = published_events.where("end_time >= ? AND start_time <= ?",
                                    @range_start.beginning_of_day, @range_end.end_of_day)
    @events = agenda.order(start_time: :asc).page(params[:page]).per(EVENTS_PER_PAGE)

    @events_by_day = @events.group_by { |event| event.start_time.to_date }
    @user_signup_event_ids = signed_up_event_ids
  end

  private

  def published_events
    events = Event.published.includes(:page, :organization, :user)
    events = events.where(type_of: params[:type_of]) if valid_type?
    events
  end

  # Every day within the grid window that a published event covers (a multi-day
  # event dots each day it spans). The card itself shows the full start–end range.
  def event_days_between(range_start, range_end)
    scope = Event.published
    scope = scope.where(type_of: params[:type_of]) if valid_type?
    scope.where("end_time >= ? AND start_time <= ?",
                range_start.beginning_of_day, range_end.end_of_day)
      .pluck(:start_time, :end_time)
      .flat_map { |start_time, end_time| (start_time.in_time_zone.to_date..end_time.in_time_zone.to_date).to_a }
      .select { |date| date >= range_start && date <= range_end }
      .to_set
  end

  def calendar_range
    start_date = parse_date(params[:start])
    end_date = parse_date(params[:end])

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
    Date.iso8601(value) if value.present?
  rescue ArgumentError, TypeError
    nil
  end

  # The month shown in the grid; falls back to the selected range's month so a
  # fresh visit (or one with no month param) still lands on the right page.
  def display_month
    parse_month(params[:month]) || @range_start.beginning_of_month
  end

  def parse_month(value)
    Date.strptime(value, "%Y-%m").beginning_of_month if value.present?
  rescue ArgumentError, TypeError
    nil
  end

  def valid_type?
    params[:type_of].present? && Event.type_ofs.key?(params[:type_of])
  end

  def signed_up_event_ids
    return Set.new unless user_signed_in?

    EventSignup.where(user: current_user, event: @events.map(&:id)).pluck(:event_id).to_set
  end
end
