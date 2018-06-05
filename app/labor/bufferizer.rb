class Bufferizer
  def initialize(article, text)
    @article = article
    @text = text
  end

  def twitter_post!
    client = Buffer::Client.new(ENV["BUFFER_ACCESS_TOKEN"])
    client.create_update(
      body: {
        text:
          twitter_buffer_text,
        profile_ids: [
          ENV["BUFFER_TWITTER_ID"],
        ],
      },
    )
    @article.update(last_buffered: Time.now)
  end

  def facebook_post!
    client = Buffer::Client.new(ENV["BUFFER_ACCESS_TOKEN"])
    client.create_update(
      body: {
        text:
          fb_buffer_text,
        profile_ids: [
          ENV["BUFFER_FACEBOOK_ID"], # We're sending to LinkedIn and FB with this.
          ENV["BUFFER_LINKEDIN_ID"], # That's why there are two profile IDs
        ],
      },
    )
    @article.update(facebook_last_buffered: Time.now)
  end

  private

  def twitter_buffer_text
    twit_name = @article.user.twitter_username
    if twit_name.present? && @text.size < 245
      "#{@text}\n{ author: @#{twit_name} }\nhttps://dev.to#{@article.path}"
    else
      "#{@text} https://dev.to#{@article.path}"
    end
  end

  def fb_buffer_text
    "#{@text} https://dev.to#{@article.path}"
  end
end
