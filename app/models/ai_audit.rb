class AiAudit < ApplicationRecord
  belongs_to :affected_user, class_name: "User", optional: true
  belongs_to :affected_content, polymorphic: true, optional: true
end
