require "rails_helper"

RSpec.describe Users::DeletedUser do
  subject(:deleted_user) { described_class }

  describe "#class_name" do
    subject(:class_name) { described_class.class_name }

    it { is_expected.to eq(User.name) }
  end

  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:deleted?) }
  it { is_expected.to respond_to(:darker_color) }
  it { is_expected.to respond_to(:username) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:summary) }
  it { is_expected.to respond_to(:twitter_username) }
  it { is_expected.to respond_to(:github_username) }
  it { is_expected.to respond_to(:profile_image_url) }
  it { is_expected.to respond_to(:decorate) }
  it { is_expected.to respond_to(:path) }
  it { is_expected.to respond_to(:tag_line) }
  it { is_expected.to respond_to(:enriched_colors) }
  it { is_expected.to respond_to(:profile_image_url_for) }
end
