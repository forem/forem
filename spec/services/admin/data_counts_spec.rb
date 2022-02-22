require "rails_helper"

RSpec.describe Admin::DataCounts, type: :service do
  it "returns proper data type" do
    expect(described_class.call).to be_an_instance_of(Hash)
  end

  it "has proper keys" do
    keys = %i[open_abuse_reports_count possible_spam_users_count
              flags_count flags_posts_count flags_comments_count flags_users_count]
    expect(described_class.call.keys).to eq(keys)
  end

  it "returns integers" do
    expect(described_class.call.values).to eq([0, 0, 0, 0, 0, 0])
  end
end
