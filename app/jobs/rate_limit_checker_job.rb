class RateLimitCheckerJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id, action)
    user = User.find_by(id: user_id)
    PingAdmins.call(user, action) if user
  end
end
