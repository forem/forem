module EventsHelper
  EVENT_TYPE_ACCENTS = {
    "live_stream" => "calendar__accent--live_stream",
    "takeover" => "calendar__accent--takeover",
    "other" => "calendar__accent--other",
    "challenge" => "calendar__accent--challenge"
  }.freeze

  def event_link_target(event)
    if event.delegate_to_page? && event.page.present?
      event.page.path
    else
      event_path(event.event_name_slug, event.event_variation_slug)
    end
  end

  def calendar_range_header(range_start, range_end)
    return "Today" if range_start == range_end && range_start == Time.zone.today
    return range_start.strftime("%a, %b %-d") if range_start == range_end

    if range_start.year == range_end.year && range_start.month == range_end.month
      "#{range_start.strftime('%b %-d')} – #{range_end.strftime('%-d')}"
    elsif range_start.year == range_end.year
      "#{range_start.strftime('%b %-d')} – #{range_end.strftime('%b %-d')}"
    else
      "#{range_start.strftime('%b %-d, %Y')} – #{range_end.strftime('%b %-d, %Y')}"
    end
  end

  def event_type_accent_class(event)
    EVENT_TYPE_ACCENTS.fetch(event.type_of.to_s, "calendar__accent--other")
  end

  # "10 Mar 09:00 – 11:00" for a same-day event; "10 Mar 09:00 – 18 Mar 17:00"
  # for a multi-day event, so the card shows both the start and end.
  def event_datetime_range(event)
    start_at = event.start_time
    end_at = event.end_time
    return start_at.to_fs(:short) if end_at.blank?

    if start_at.to_date == end_at.to_date
      "#{start_at.to_fs(:short)} – #{end_at.strftime('%H:%M')}"
    else
      "#{start_at.to_fs(:short)} – #{end_at.to_fs(:short)}"
    end
  end
end
