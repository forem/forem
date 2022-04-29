require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220429142653_remove_mailchimp_sustaining_members_newsletter.rb",
)

describe DataUpdateScripts::RemoveMailchimpSustainingMembersNewsletter do
  it "does nothing when setting not present" do
    expect { described_class.new.run }.not_to change(Settings::General, :count)
  end

  context "when there is a newsletter setting" do
    before do
      # since it's been removed from the code, define it here in test
      Settings::General.setting(:mailchimp_sustaining_members_id)
      # setting the value changes count to 1
      Settings::General.mailchimp_sustaining_members_id = "abcdefgh"
    end

    it "removes mailchimp_sustaining_members_id setting" do
      expect { described_class.new.run }.to change(Settings::General, :count).by(-1)
    end
  end
end
