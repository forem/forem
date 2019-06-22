class DECSSnippetService
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def call
    HTTParty.get(url).parsed_response
  end
end
