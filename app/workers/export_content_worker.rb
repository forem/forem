class ExportContentWorker
  include Sidekiq::Job

  sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executed

  def perform(user_id, email)
    user = User.find_by(id: user_id)

    Exporter::Service.new(user).export(email) if user
  end
end
