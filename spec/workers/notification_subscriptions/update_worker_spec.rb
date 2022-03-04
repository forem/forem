require "rails_helper"

RSpec.describe NotificationSubscriptions::UpdateWorker do
  describe "#perform_now" do
    let(:id) { rand(1000) }
    let(:worker) { subject }

    before do
      allow(NotificationSubscriptions::Update).to receive(:call)
    end

    describe "when wrong class is passed" do
      it "raises an exception" do
        allow(User).to receive(:find_by).with(id).and_return(double)
        expect do
          worker.perform(id, "User")
        end.to raise_error(NotificationSubscriptions::InvalidNotifiableForUpdate, "User")
      end
    end

    describe "when notifiable is not found" do
      it "does not call the service" do
        allow(Article).to receive(:find_by).with(id: id).and_return(nil)
        worker.perform(id, "Article")
        expect(NotificationSubscriptions::Update).not_to have_received(:call)
      end
    end

    describe "when notifiable is found" do
      it "calls the service" do
        article = double
        allow(Article).to receive(:find_by).with(id: id).and_return(article)
        worker.perform(id, "Article")
        expect(NotificationSubscriptions::Update).to have_received(:call).with(article)
      end
    end
  end
end
