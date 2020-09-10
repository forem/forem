class ExportContentWorker
  include Sidekiq::Worker

  sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executed

  def perform(user_id, send_to_admin: false)
    user = User.find_by(id: user_id)

    Exporter::Service.new(user).export(send_to_admin: send_to_admin) if user
  end
end
