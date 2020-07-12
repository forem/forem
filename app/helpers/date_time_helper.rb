module DateTimeHelper
  def local_date(datetime)
    tag.time(
      datetime.strftime("%b %e, %Y"),
      datetime: datetime.iso8601,
      class: "date",
    )
  end
end
