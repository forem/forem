class RssReaderFetchUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :medium_priority

  def perform(user_id)
    user = User.find_by(id: user_id)

    RssReader.new.fetch_user(user) if user&.feed_url.present?
  end
end
