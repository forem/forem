module DateHelper
  def local_date(datetime, show_year: true)
    datetime = Time.zone.parse(datetime) if datetime.is_a?(String)

    tag.time(
      I18n.l(datetime, format: "%b %-e#{', %Y' if show_year}"),
      datetime: datetime.utc.iso8601,
      class: "date#{'-no-year' unless show_year}",
    )
  end
end
