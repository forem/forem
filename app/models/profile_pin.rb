class ProfilePin < ApplicationRecord
  belongs_to :pinnable, polymorphic: true
  belongs_to :profile, polymorphic: true

end
