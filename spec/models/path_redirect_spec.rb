require "rails_helper"

RSpec.describe PathRedirect, type: :model do
  subject { build(:path_redirect) }

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:old_path) }
    it { is_expected.to validate_presence_of(:old_path) }
    it { is_expected.to validate_presence_of(:new_path) }
    it { is_expected.to validate_inclusion_of(:source).in_array(%w[admin service]) }

    it "validates old_path is not the same as the new_path" do
      same_paths_path_redirect = build(:path_redirect, old_path: "/the-same-path", new_path: "/the-same-path")

      expect(same_paths_path_redirect).not_to be_valid

      expected_error_message = "the old_path cannot be the same as the new_path"
      expect(same_paths_path_redirect.errors.full_messages.join).to include(expected_error_message)
    end

    it "validates new_path is not already being redirected" do
      path_redirect1 = create(:path_redirect)
      path_redirect2 = build(:path_redirect, new_path: path_redirect1.old_path)

      expect(path_redirect2).not_to be_valid
      expect(path_redirect2.errors.full_messages.join).to include("this new_path is already being redirected")
    end
  end

  describe "before_save" do
    it "increments the version by 1 if the new_path is updated" do
      path_redirect = create(:path_redirect)
      expect(path_redirect.version).to eq 1
      path_redirect.update(new_path: "/some-new-path")
      expect(path_redirect.version).to eq 2
    end

    it "does not increment the version if a field other than new_path is updated" do
      path_redirect = create(:path_redirect)
      expect(path_redirect.version).to eq 1
      path_redirect.update(old_path: "/some-old-path")
      expect(path_redirect.version).to eq 1
    end
  end
end
