# app/services/reddit_json_from_url_service.rb
class RedditJsonFromUrlService
  def initialize(url)
    @url = ActionController::Base.helpers.strip_tags(url).strip
  end

  def parse
    json = HTTParty.get("#{@url}.json", headers: { "User-Agent" => "ThePracticalDev" })
    # The JSON response is an array with two items.
    # The first one is the post itself, the second one are the comments
    data = json.first["data"]["children"][0]["data"]

    {
      author: data["author"],
      title: data["title"],
      url: @url,
      thumbnail: data["thumbnail"]
    }
  end
end
