require "rails_helper"

RSpec.describe Notifications::UpdateWorker do
  describe "#perform_now" do
    let(:id) { rand(1000) }
    let(:worker) { subject }

    before do
      allow(Notifications::Update).to receive(:call)
    end

    describe "when wrong class is passed" do
      it "raises an exception" do
        allow(User).to receive(:find_by).with(id).and_return(double)
        expect do
          worker.perform(id, "User")
        end.to raise_error(Notifications::InvalidNotifiableForUpdate, "User")
      end
    end

    describe "when notifiable is not found" do
      it "does not call the service" do
        allow(Comment).to receive(:find_by).with(id: id).and_return(nil)
        worker.perform(id, "Comment", nil)
        expect(Notifications::Update).not_to have_received(:call)
      end
    end

    describe "when notifiable is found" do
      it "calls the service" do
        article = double
        allow(Article).to receive(:find_by).with(id: id).and_return(article)
        worker.perform(id, "Article", "Published")
        expect(Notifications::Update).to have_received(:call).with(article, "Published")
      end
    end
  end
end
