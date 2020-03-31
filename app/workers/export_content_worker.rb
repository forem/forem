class ExportContentWorker
  include Sidekiq::Worker

  sidekiq_options queue: :medium_priority, retry: 10

  def perform(user_id)
    user = User.find_by(id: user_id)

    Exporter::Service.new(user).export(send_email: true) if user
  end
end
