module CalendarHelper
  # The day links of the calendar widget's month grid, one per day from grid_start to grid_end.
  # selected_range is the highlighted Date range (nil when nothing is selected) and type_of is
  # the event type filter each link keeps.
  def calendar_grid_days_html(grid_start, grid_end, display_month:, event_days:, selected_range:, today:, type_of:)
    html = ForemNative.calendar_grid_days_html(
      grid_start.jd, grid_end.jd, display_month.month, event_days.map(&:jd), !selected_range.nil?,
      selected_range&.begin&.jd || 0, selected_range&.end&.jd || 0, today.jd, calendar_path, type_of
    )
    return html.html_safe if html # rubocop:disable Rails/OutputSafety

    legacy_calendar_grid_days_html(grid_start, grid_end, display_month: display_month, event_days: event_days,
                                                         selected_range: selected_range, today: today, type_of: type_of)
  end

  private

  # Handles what ForemNative declines: type_of values that need escaping (or arrive as
  # Arrays), and grids outside the Gregorian 1583-9999 range.
  def legacy_calendar_grid_days_html(grid_start, grid_end, display_month:, event_days:, selected_range:, today:,
                                     type_of:)
    days = (grid_start..grid_end).map do |day|
      classes = %w[calendar__day text-center p-1]
      classes << "color-base-30" unless day.month == display_month.month
      classes << "calendar__day--has-event" if event_days.include?(day)
      classes << "calendar__day--selected" if selected_range && day >= selected_range.begin && day <= selected_range.end
      classes << "calendar__day--today" if day == today

      link_to day.day,
              calendar_path(start: day.iso8601, end: day.iso8601, type_of: type_of),
              class: classes.join(" "),
              data: { calendar_day: day.iso8601 }
    end
    safe_join(days, "\n")
  end
end
