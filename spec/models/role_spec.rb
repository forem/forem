require "rails_helper"

RSpec.describe Role, type: :model do
  it { is_expected.to belong_to(:resource).optional }
  it { is_expected.to validate_inclusion_of(:resource_type).in_array(Rolify.resource_types) }
  it { is_expected.to validate_inclusion_of(:name).in_array(%w[super_admin admin single_resource_admin tech_admin tag_moderator trusted banned warned workshop_pass chatroom_beta_tester comment_banned pro podcast_admin]) }
end
