require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Search::IndexJob, type: :job do
  it "does nothing if there is wrong record type is passed" do
    expect { described_class.perform_now("SuperUser", 1) }.to raise_error(Search::InvalidRecordType)
  end

  it "doesn't fail if a record is not found" do
    expect { described_class.perform_now("Comment", -1) }.not_to raise_error
  end

  it "indexes a record if everything is fine" do
    user = double
    allow(user).to receive(:index!)
    allow(User).to receive(:find_by).and_return(user)
    described_class.perform_now("User", 1)
    expect(user).to have_received(:index!)
  end
end
