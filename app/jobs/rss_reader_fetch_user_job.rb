class RssReaderFetchUserJob < ApplicationJob
  queue_as :rss_reader_fetch_user

  def perform(user_id, service = RssReader.new)
    user = User.find_by(id: user_id)

    service.fetch_user(user) if user&.feed_url.present?
  end
end
