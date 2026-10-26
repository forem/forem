module Spam
  class DomainDetectorWorker
    include Sidekiq::Job

    sidekiq_options queue: :default, retry: 5

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Spam::DomainDetector.new(user).check_and_block_domain!
    end
  end
end
