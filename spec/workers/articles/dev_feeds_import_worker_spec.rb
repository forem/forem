require "rails_helper"

RSpec.describe Articles::DevFeedsImportWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "does not call the Feeds::Import for non DEV communities" do
      allow(SiteConfig).to receive(:community_name).and_return("NotDEV")
      allow(Feeds::Import).to receive(:call)

      worker.perform

      expect(Feeds::Import).not_to have_received(:call)
    end

    it "does not call Feeds::Import if the cache instructs it to cancel" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV")
      allow(Rails.cache).to receive(:read).with("cancel_feeds_import").and_return("true")

      allow(Feeds::Import).to receive(:call)

      worker.perform

      expect(Feeds::Import).not_to have_received(:call)
    end

    it "calls the Feeds::Import to get all articles" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV")
      allow(Rails.cache).to receive(:read).with("cancel_feeds_import").and_return(nil)
      allow(Feeds::Import).to receive(:call)

      worker.perform

      expect(Feeds::Import).to have_received(:call)
    end

    context "with user ids" do
      before do
        allow(SiteConfig).to receive(:community_name).and_return("DEV")
      end

      it "calls Feeds::Import with the correct users if given user ids" do
        user = create(:user)
        allow(Feeds::Import).to receive(:call)

        worker.perform([user.id])

        expect(Feeds::Import).to have_received(:call).with(users: User.where(id: [user.id]))
      end
    end
  end
end
