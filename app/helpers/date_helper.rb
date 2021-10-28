module DateHelper
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
