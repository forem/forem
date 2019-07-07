class BackupData < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :instance_user, class_name: "User"
  validates :instance_id, :instance_type, :json_data, presence: true

  def self.backup!(instance)
    BackupData.create!(instance_type: instance.class.name, instance_id: instance.id, instance_user_id: instance.user_id, json_data: instance.attributes)
  end

  def recover!
    instance = instance_type.constantize.create!(json_data.to_h)
    destroy!
    instance
  end
end
