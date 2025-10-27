require "rails_helper"

RSpec.describe Emails::SendUserDigestWorker, type: :worker do
  let(:worker) { subject }
  let(:user) do
    u = create(:user)
    u.notification_setting.update(email_digest_periodic: true)
    u
  end
  let(:author) { create(:user) }
  let(:tag)    { create(:tag) }
  let(:default_subforem) { create(:subforem, domain: "default.test") }
  let(:mailer)           { double }
  let(:message_delivery) { double }

  before do
    # Set up default subforem for testing
    RequestStore.store[:default_subforem_id] = default_subforem.id
    allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)

    allow(DigestMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:digest_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
  end

  after do
    # Clean up RequestStore after each test
    RequestStore.store[:default_subforem_id] = nil
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "perform" do
    context "when there's articles to be sent" do
      before do
        user.follow(author)
        user.follow(tag)
      end

      it "send digest email when there are at least 3 hot articles" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with).with(user: user, articles: Array, billboards: Array)
        expect(mailer).to have_received(:digest_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "does not send email when user does not have email_digest_periodic" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        user.notification_setting.update_column(:email_digest_periodic, false)
        worker.perform(user.id)

        expect(DigestMailer).not_to have_received(:with)
      end

      it "does not send email when user is not registered" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])
        user.update_column(:registered, false)
        worker.perform(user.id)

        expect(DigestMailer).not_to have_received(:with)
      end

      it "includes billboards" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])
        bb_1 = create(:billboard, placement_area: "digest_first",  published: true, approved: true)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with) do |args|
          expect(args[:billboards]).to contain_exactly(bb_1, bb_2)
        end
      end

      it "creates billboard events when billboards are present" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])
        bb_1 = create(:billboard, placement_area: "digest_first",  published: true, approved: true)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

        worker.perform(user.id)

        expect(BillboardEvent.where(billboard_id: bb_1.id, category: "impression").size).to be(1)
        expect(BillboardEvent.where(billboard_id: bb_2.id, category: "impression").size).to be(1)
      end

      context "when there's a preferred paired billboard" do
        let!(:bb_1) do
          create(
            :billboard,
            placement_area: "digest_first",
            published: true,
            approved: true,
          )
        end
        let!(:paired_bb) do
          create(
            :billboard,
            placement_area: "digest_second",
            published: true,
            approved: true,
            prefer_paired_with_billboard_id: bb_1.id,
          )
        end
        let!(:other_bb) do
          create(
            :billboard,
            placement_area: "digest_second",
            published: true,
            approved: true,
          )
        end

        it "selects the paired billboard for the second slot" do
          create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])

          worker.perform(user.id)

          expect(DigestMailer).to have_received(:with) do |args|
            expect(args[:billboards]).to eq([bb_1, paired_bb])
          end
        end

        it "creates events for both the first and the paired second billboard" do
          create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, tag_list: [tag.name])

          worker.perform(user.id)

          expect(BillboardEvent.where(billboard_id: bb_1.id,      category: "impression").count).to eq(1)
          expect(BillboardEvent.where(billboard_id: paired_bb.id, category: "impression").count).to eq(1)
          # and it should *not* fire for the other_bb
          expect(BillboardEvent.where(billboard_id: other_bb.id).count).to eq(0)
        end
      end
    end
  end
end
