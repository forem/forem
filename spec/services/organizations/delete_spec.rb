require "rails_helper"

RSpec.describe Organizations::Delete, type: :service do
  let(:org) { create(:organization) }

  it "deletes an organization" do
    described_class.call(org)
    expect(Organization.find_by(id: org.id)).to be_nil
  end
end
