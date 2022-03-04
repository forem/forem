require "rails_helper"

RSpec.describe Articles::CachedEntity, type: :model do
  subject(:struct) { described_class.from_object(object) }

  let(:object) { build(:user) }

  it { is_expected.to respond_to(:profile_image_url_for) }
end
