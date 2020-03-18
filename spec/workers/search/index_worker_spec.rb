require "rails_helper"

RSpec.describe Search::IndexWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", ["User", 1]

  it "does nothing if there is wrong record type is passed" do
    expect { worker.perform("SuperUser", 1) }.to raise_error(Search::InvalidRecordType)
  end

  it "doesn't fail if a record is not found" do
    expect { worker.perform("User", -1) }.not_to raise_error
  end

  it "indexes a record if everything is fine" do
    user = double
    allow(user).to receive(:index!)
    allow(User).to receive(:find_by).and_return(user)
    worker.perform("User", 1)
    expect(user).to have_received(:index!)
  end
end
