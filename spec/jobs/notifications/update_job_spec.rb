require "rails_helper"

RSpec.describe Notifications::UpdateJob do
  include_examples "#enqueues_job", "update_notifications", 1, "Article"

  describe "#perform_now" do
    let(:id) { rand(1000) }
    let(:update_service) { double }

    before do
      allow(update_service).to receive(:call)
    end

    describe "when wrong class is passed" do
      it "raises an exception" do
        allow(User).to receive(:find_by).with(id).and_return(double)
        expect do
          described_class.perform_now(id, "User")
        end.to raise_error(Notifications::InvalidNotifiableForUpdate, "User")
      end
    end

    describe "when notifiable is not found" do
      it "does not call the service" do
        allow(Comment).to receive(:find_by).with(id: id).and_return(nil)
        described_class.perform_now(id, "Comment", nil, update_service)
        expect(update_service).not_to have_received(:call)
      end
    end

    describe "when notifiable is found" do
      it "calls the service" do
        article = double
        allow(Article).to receive(:find_by).with(id: id).and_return(article)
        described_class.perform_now(id, "Article", "Published", update_service)
        expect(update_service).to have_received(:call).with(article, "Published")
      end
    end
  end
end
