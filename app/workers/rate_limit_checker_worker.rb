# TODO: [@thepracticaldev/oss] remove this when Sidekiq has exhausted these workers
class RateLimitCheckerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 10

  def perform(user_id, action)
    user = User.find_by(id: user_id)
    PingAdmins.call(user, action) if user
  end
end
