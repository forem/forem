class ExportContentJob < ApplicationJob
  queue_as :export_content

  def perform(user_id, exporter = Exporter::Service)
    user = User.find_by(id: user_id)
    exporter.new(user).export(send_email: true) if user
  end
end
