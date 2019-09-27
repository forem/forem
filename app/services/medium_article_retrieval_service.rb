class MediumArticleRetrievalService
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    html = HTTParty.get(url)
    page = Nokogiri::HTML(html)

    title = page.at("meta[name='title']")["content"]
    reading_time = page.at("meta[name='twitter:data1']")["value"]
    author = page.at("meta[name='author']")["content"]
    author_image = page.at("img[alt='#{author}']")["src"]

    {
      title: title,
      author: author,
      author_image: author_image,
      reading_time: reading_time,
      url: url
    }
  end
end
