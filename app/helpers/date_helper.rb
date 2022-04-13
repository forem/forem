module DateHelper
  # Provides a formatted date as a <time> tag
  # @param datetime Date, DateTime or Time object.
  # @param show_year [Boolean] show the year in the formatted date string
  # @return [String] example: "<time datetime="2022-03-19T20:03:59Z" class="date">Mar 19, 2022</time>" if valid date
  # @return [FalseClass] if datetime is nil
  def local_date_tag(datetime, show_year: true)
    tag.time(
      local_date(datetime, show_year: show_year),
      datetime: datetime.utc.iso8601,
      class: "date#{'-no-year' unless show_year}",
    )
  end

  def local_date(datetime, show_year: true)
    datetime = Time.zone.parse(datetime) if datetime.is_a?(String)
    format = show_year ? :short_with_year : :short

    tag.time(
      l(datetime, format: format),
      datetime: datetime.utc.iso8601,
      class: "date#{'-no-year' unless show_year}",
    )
  end
end
