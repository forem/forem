require "rails_helper"

RSpec.describe SubforemReassignmentService do
  let(:user) { create(:user) }
  let(:current_subforem) { create(:subforem, domain: "tech.example.com", discoverable: true) }
  let(:target_subforem) { create(:subforem, domain: "dev.example.com", discoverable: true) }
  let(:misc_subforem) { create(:subforem, domain: "misc.example.com", misc: true, discoverable: true) }
  let(:non_discoverable_subforem) { create(:subforem, domain: "private.example.com", discoverable: false) }
  let(:article) { create(:article, user: user, subforem_id: current_subforem.id) }

  describe "#check_and_reassign" do

    context "when article has an offtopic automod label" do
      before do
        article.update!(automod_label: "ok_but_offtopic_for_subforem")
      end

      context "when AI finds an appropriate subforem" do
        before do
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "reassigns the article to the new subforem" do
          expect { described_class.new(article).check_and_reassign }.to change { article.reload.subforem_id }
            .from(current_subforem.id).to(target_subforem.id)
        end

        it "sends a notification about the change" do
          expect(Notifications::SubforemChangeNotificationWorker).to receive(:perform_async)
            .with(article.id, current_subforem.id, target_subforem.id)

          described_class.new(article).check_and_reassign
        end

        it "logs the reassignment" do
          expect(Rails.logger).to receive(:info)
            .with("Article #{article.id} reassigned from subforem #{current_subforem.id} to #{target_subforem.id}")

          described_class.new(article).check_and_reassign
        end

        it "returns true" do
          expect(described_class.new(article).check_and_reassign).to be true
        end

        it "updates the automod label to on-topic equivalent" do
          expect { described_class.new(article).check_and_reassign }
            .to change { article.reload.automod_label }
            .from("ok_but_offtopic_for_subforem").to("okay_and_on_topic")
        end
      end

      context "when AI does not find an appropriate subforem" do
        before do
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(nil)
        end

        it "does not reassign the article" do
          expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
        end

        it "does not send a notification" do
          expect(Notifications::SubforemChangeNotificationWorker).not_to receive(:perform_async)

          described_class.new(article).check_and_reassign
        end

        it "returns false" do
          expect(described_class.new(article).check_and_reassign).to be false
        end
      end

      context "when AI finds a misc subforem as fallback" do
        before do
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(misc_subforem.id)
        end

        it "reassigns the article to the misc subforem" do
          expect { described_class.new(article).check_and_reassign }.to change { article.reload.subforem_id }
            .from(current_subforem.id).to(misc_subforem.id)
        end

        it "sends a notification about the change to misc subforem" do
          expect(Notifications::SubforemChangeNotificationWorker).to receive(:perform_async)
            .with(article.id, current_subforem.id, misc_subforem.id)

          described_class.new(article).check_and_reassign
        end

        it "returns true" do
          expect(described_class.new(article).check_and_reassign).to be true
        end

        it "updates the automod label to on-topic equivalent for misc subforem" do
          expect { described_class.new(article).check_and_reassign }
            .to change { article.reload.automod_label }
            .from("ok_but_offtopic_for_subforem").to("okay_and_on_topic")
        end
      end

      context "when AI finds a non-discoverable subforem" do
        before do
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(non_discoverable_subforem.id)
        end

        it "reassigns the article to the non-discoverable subforem" do
          expect { described_class.new(article).check_and_reassign }.to change { article.reload.subforem_id }
            .from(current_subforem.id).to(non_discoverable_subforem.id)
        end

        it "sends a notification about the change" do
          expect(Notifications::SubforemChangeNotificationWorker).to receive(:perform_async)
            .with(article.id, current_subforem.id, non_discoverable_subforem.id)

          described_class.new(article).check_and_reassign
        end

        it "updates the automod label to on-topic equivalent for non-discoverable subforem" do
          expect { described_class.new(article).check_and_reassign }
            .to change { article.reload.automod_label }
            .from("ok_but_offtopic_for_subforem").to("okay_and_on_topic")
        end
      end

      context "when AI service raises an error" do
        before do
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_raise(StandardError, "AI service error")
        end

        it "does not reassign the article" do
          expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
        end

        it "logs the error" do
          expect(Rails.logger).to receive(:error)
            .with("Failed to find appropriate subforem for article #{article.id}: AI service error")

          described_class.new(article).check_and_reassign
        end

        it "returns false" do
          expect(described_class.new(article).check_and_reassign).to be false
        end
      end

      context "when user has disabled subforem reassignment" do
        before do
          user.setting.update!(disallow_subforem_reassignment: true)
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "does not reassign the article" do
          expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
        end

        it "does not send a notification" do
          expect(Notifications::SubforemChangeNotificationWorker).not_to receive(:perform_async)

          described_class.new(article).check_and_reassign
        end

        it "does not call the AI service" do
          expect(Ai::SubforemFinder).not_to receive(:new)
          described_class.new(article).check_and_reassign
        end

        it "returns false" do
          expect(described_class.new(article).check_and_reassign).to be false
        end

        it "does not update the automod label" do
          expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.automod_label }
        end
      end

      context "when user has no setting record" do
        before do
          user.setting.destroy!
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "reassigns the article (defaults to allowing reassignment)" do
          expect { described_class.new(article).check_and_reassign }.to change { article.reload.subforem_id }
            .from(current_subforem.id).to(target_subforem.id)
        end

        it "returns true" do
          expect(described_class.new(article).check_and_reassign).to be true
        end
      end

      context "when article has no user" do
        before do
          allow(article).to receive(:user).and_return(nil)
          # Mock the update! method to avoid validation issues when user is nil
          allow(article).to receive(:update!) do |attributes|
            article.assign_attributes(attributes)
            article.save!(validate: false)
          end
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "reassigns the article (defaults to allowing reassignment)" do
          expect { described_class.new(article).check_and_reassign }.to change { article.reload.subforem_id }
            .from(current_subforem.id).to(target_subforem.id)
        end

        it "returns true" do
          expect(described_class.new(article).check_and_reassign).to be true
        end
      end
    end

    context "when article does not have an offtopic automod label" do
      context "with on-topic labels" do
        %w[
          okay_and_on_topic
          very_good_and_on_topic
          great_and_on_topic
        ].each do |label|
          context "with #{label}" do
            before { article.update!(automod_label: label) }

            it "does not reassign the article" do
              expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
            end

            it "does not call the AI service" do
              expect(Ai::SubforemFinder).not_to receive(:new)
              described_class.new(article).check_and_reassign
            end

            it "returns false" do
              expect(described_class.new(article).check_and_reassign).to be false
            end
          end
        end
      end

      context "with spam labels" do
        %w[
          clear_and_obvious_spam
          likely_spam
          clear_and_obvious_harmful
          likely_harmful
          clear_and_obvious_inciting
          likely_inciting
          clear_and_obvious_low_quality
          likely_low_quality
        ].each do |label|
          context "with #{label}" do
            before { article.update!(automod_label: label) }

            it "does not reassign the article" do
              expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
            end

            it "does not call the AI service" do
              expect(Ai::SubforemFinder).not_to receive(:new)
              described_class.new(article).check_and_reassign
            end

            it "returns false" do
              expect(described_class.new(article).check_and_reassign).to be false
            end
          end
        end
      end

      context "with no moderation label" do
        before { article.update!(automod_label: "no_moderation_label") }

        it "does not reassign the article" do
          expect { described_class.new(article).check_and_reassign }.not_to change { article.reload.subforem_id }
        end

        it "does not call the AI service" do
          expect(Ai::SubforemFinder).not_to receive(:new)
          described_class.new(article).check_and_reassign
        end

        it "returns false" do
          expect(described_class.new(article).check_and_reassign).to be false
        end
      end
    end

    context "with different offtopic automod labels" do
      context "with very_good_but_offtopic_for_subforem" do
        before do
          article.update!(automod_label: "very_good_but_offtopic_for_subforem")
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "updates automod label to very_good_and_on_topic" do
          expect { described_class.new(article).check_and_reassign }
            .to change { article.reload.automod_label }
            .from("very_good_but_offtopic_for_subforem").to("very_good_and_on_topic")
        end
      end

      context "with great_but_off_topic_for_subforem" do
        before do
          article.update!(automod_label: "great_but_off_topic_for_subforem")
          allow_any_instance_of(Ai::SubforemFinder).to receive(:find_appropriate_subforem).and_return(target_subforem.id)
        end

        it "updates automod label to great_and_on_topic" do
          expect { described_class.new(article).check_and_reassign }
            .to change { article.reload.automod_label }
            .from("great_but_off_topic_for_subforem").to("great_and_on_topic")
        end
      end
    end
  end

  describe "#should_reassign?" do
    it "returns true for offtopic labels that are not spam and user allows reassignment" do
      %w[
        ok_but_offtopic_for_subforem
        very_good_but_offtopic_for_subforem
        great_but_off_topic_for_subforem
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:should_reassign?)).to be true
      end
    end

    it "returns false for offtopic labels when user disallows reassignment" do
      user.setting.update!(disallow_subforem_reassignment: true)
      %w[
        ok_but_offtopic_for_subforem
        very_good_but_offtopic_for_subforem
        great_but_off_topic_for_subforem
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:should_reassign?)).to be false
      end
    end

    it "returns false for non-offtopic labels" do
      %w[
        no_moderation_label
        okay_and_on_topic
        very_good_and_on_topic
        great_and_on_topic
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:should_reassign?)).to be false
      end
    end

    it "returns false for spam labels even if they are offtopic" do
      %w[
        clear_and_obvious_spam
        likely_spam
        clear_and_obvious_harmful
        likely_harmful
        clear_and_obvious_inciting
        likely_inciting
        clear_and_obvious_low_quality
        likely_low_quality
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:should_reassign?)).to be false
      end
    end
  end

  describe "#spam_label?" do
    it "returns true for spam labels" do
      %w[
        clear_and_obvious_spam
        likely_spam
        clear_and_obvious_harmful
        likely_harmful
        clear_and_obvious_inciting
        likely_inciting
        clear_and_obvious_low_quality
        likely_low_quality
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:spam_label?)).to be true
      end
    end

    it "returns false for non-spam labels" do
      %w[
        no_moderation_label
        ok_but_offtopic_for_subforem
        okay_and_on_topic
        very_good_but_offtopic_for_subforem
        very_good_and_on_topic
        great_but_off_topic_for_subforem
        great_and_on_topic
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:spam_label?)).to be false
      end
    end
  end

  describe "#on_topic_equivalent_label" do
    it "returns the correct on-topic equivalent for offtopic labels" do
      article.update!(automod_label: "ok_but_offtopic_for_subforem")
      expect(described_class.new(article).send(:on_topic_equivalent_label)).to eq("okay_and_on_topic")

      article.update!(automod_label: "very_good_but_offtopic_for_subforem")
      expect(described_class.new(article).send(:on_topic_equivalent_label)).to eq("very_good_and_on_topic")

      article.update!(automod_label: "great_but_off_topic_for_subforem")
      expect(described_class.new(article).send(:on_topic_equivalent_label)).to eq("great_and_on_topic")
    end

    it "returns nil for non-offtopic labels" do
      %w[
        no_moderation_label
        clear_and_obvious_spam
        okay_and_on_topic
        very_good_and_on_topic
        great_and_on_topic
      ].each do |label|
        article.update!(automod_label: label)
        expect(described_class.new(article).send(:on_topic_equivalent_label)).to be_nil
      end
    end
  end

  describe "#user_allows_reassignment?" do
    context "when user has setting with disallow_subforem_reassignment false" do
      before { user.setting.update!(disallow_subforem_reassignment: false) }

      it "returns true" do
        expect(described_class.new(article).send(:user_allows_reassignment?)).to be true
      end
    end

    context "when user has setting with disallow_subforem_reassignment true" do
      before { user.setting.update!(disallow_subforem_reassignment: true) }

      it "returns false" do
        expect(described_class.new(article).send(:user_allows_reassignment?)).to be false
      end
    end

    context "when user has no setting record" do
      before { user.setting.destroy! }

      it "returns true (defaults to allowing reassignment)" do
        expect(described_class.new(article).send(:user_allows_reassignment?)).to be true
      end
    end

    context "when article has no user" do
      before do
        allow(article).to receive(:user).and_return(nil)
        allow(article).to receive(:user_id).and_return(nil)
      end

      it "returns true (defaults to allowing reassignment)" do
        expect(described_class.new(article).send(:user_allows_reassignment?)).to be true
      end
    end
  end
end
