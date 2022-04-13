module DateHelper
  # Provides a formatted date as a <time> tag
  # @param datetime Date, DateTime or Time object.
  # @param show_year [Boolean] show the year in the formatted date string
  # @return [String] example: "<time datetime="2022-03-19T20:03:59Z" class="date">Mar 19, 2022</time>" if valid date
  # @return [FalseClass] if datetime is nil
  def local_date_tag(datetime, show_year: true)
    return if datetime.blank?

    tag.time(
      local_date(datetime, show_year: show_year),
      datetime: datetime.utc.iso8601,
      class: "date#{'-no-year' unless show_year}",
    )
  end

  # Provides a formatted date value
  # @param datetime Date, DateTime or Time object.
  # @param show_year [Boolean] show the year in the formatted date string
  # @return [String] example: "Mar 19, 2022" if the date is valid
  # @return [FalseClass] if datetime is nil
  def local_date(datetime, show_year: true)
    return if datetime.blank?

    datetime = Time.zone.parse(datetime) if datetime.is_a?(String)
    format = show_year ? :short_with_year : :short

    l(datetime, format: format)
  end
end
