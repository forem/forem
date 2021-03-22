class MediumArticleRetrievalService
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def self.call(...)
    new(...).call
  end

  def call
    response = HTTParty.get(url)
    page = Nokogiri::HTML(response.body)

    title = page.at("meta[name='title']")["content"]
    reading_time = page.at("meta[name='twitter:data1']")["value"]
    author = page.at("meta[name='author']")["content"]
    author_image = page.at("img[alt='#{author}']")["src"]
    published_time = page.at("meta[property='article:published_time']")["content"]

    {
      title: title,
      author: author,
      author_image: author_image,
      reading_time: reading_time,
      published_time: published_time,
      publication_date: publication_date(published_time),
      url: url
    }
  end

  private

  def publication_date(published_time)
    Time.zone.parse(published_time).strftime("%b %-d, %Y")
  rescue ArgumentError, NoMethodError => e
    Rails.logger.error("#{published_time} is not a valid date: #{e}")
  end
end
