class MediumArticleRetrievalService
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def call
    html = HTTParty.get(url)
    page = Nokogiri::HTML(html)

    title = page.css("h1").first.content
    author_image = page.css("img.avatar-image").first.attributes["src"].value
    reading_time = page.css("span.readingTime").first.values.last
    author = page.css("a[data-user-id]")[1].content

    {
      title: title,
      author: author,
      author_image: author_image,
      reading_time: reading_time,
      url: url
    }
  end
end
