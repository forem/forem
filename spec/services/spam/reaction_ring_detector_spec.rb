# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spam::ReactionRingDetector, type: :service do
  let(:user) { create(:user, reputation_modifier: 1.0) }
  let(:detector) { described_class.new(user.id) }

  describe "#call" do
    context "when user has insufficient reactions" do
      before do
        # Create fewer than 50 reactions
        create_list(:reaction, 30, user: user, reactable_type: "Article", category: "like")
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when user is admin" do
      before do
        user.update!(any_admin: true)
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like")
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when user is trusted" do
      before do
        user.update!(trusted: true)
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like")
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when no potential ring is found" do
      before do
        # Create enough reactions but no other users with similar patterns
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like")
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when a legitimate reaction ring is detected" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:author3) { create(:user) }
      let(:ring_member1) { create(:user, reputation_modifier: 1.0) }
      let(:ring_member2) { create(:user, reputation_modifier: 1.0) }
      let(:ring_member3) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by the target authors
        articles_author1 = create_list(:article, 10, user: author1, published: true)
        articles_author2 = create_list(:article, 10, user: author2, published: true)
        articles_author3 = create_list(:article, 10, user: author3, published: true)

        # Create reactions by the main user to these authors' articles
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like") }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like") }
        articles_author3.each { |article| create(:reaction, user: user, reactable: article, category: "like") }

        # Create reactions by ring members to the same authors' articles
        [ring_member1, ring_member2, ring_member3].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
          articles_author2.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
          articles_author3.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
        end

        # Add some diverse reactions to avoid false positive detection
        other_author = create(:user)
        other_articles = create_list(:article, 5, user: other_author, published: true)
        other_articles.each { |article| create(:reaction, user: user, reactable: article, category: "like") }
      end

      it "detects the ring and adjusts reputation modifiers" do
        expect(detector.call).to be true

        # Check that reputation modifiers were set to 0
        expect(user.reload.reputation_modifier).to eq(0.0)
        expect(ring_member1.reload.reputation_modifier).to eq(0.0)
        expect(ring_member2.reload.reputation_modifier).to eq(0.0)
        expect(ring_member3.reload.reputation_modifier).to eq(0.0)

        # Check that notes were created
        expect(Note.where(noteable: user, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member1, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member2, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member3, reason: "reaction_ring_detection")).to exist
      end
    end

    context "when users have legitimate community connections" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:legitimate_member1) { create(:user, reputation_modifier: 1.0) }
      let(:legitimate_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 10, user: author1, published: true)
        articles_author2 = create_list(:article, 10, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like") }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like") }

        # Create reactions by legitimate members
        [legitimate_member1, legitimate_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
          articles_author2.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
        end

        # Create legitimate connections (following relationships)
        user.follow(legitimate_member1)
        user.follow(legitimate_member2)

        # Add diverse reactions to show legitimate community behavior
        other_authors = create_list(:user, 3)
        other_authors.each do |other_author|
          other_articles = create_list(:article, 3, user: other_author, published: true)
          other_articles.each { |article| create(:reaction, user: legitimate_member1, reactable: article, category: "like") }
        end
      end

      it "does not detect a ring due to legitimate connections" do
        expect(detector.call).to be false

        # Check that reputation modifiers were not changed
        expect(user.reload.reputation_modifier).to eq(1.0)
        expect(legitimate_member1.reload.reputation_modifier).to eq(1.0)
        expect(legitimate_member2.reload.reputation_modifier).to eq(1.0)
      end
    end

    context "when users are in the same organization" do
      let(:organization) { create(:organization) }
      let(:author1) { create(:user) }
      let(:org_member1) { create(:user, organization: organization, reputation_modifier: 1.0) }
      let(:org_member2) { create(:user, organization: organization, reputation_modifier: 1.0) }

      before do
        user.update!(organization: organization)

        # Create articles by target author
        articles_author1 = create_list(:article, 10, user: author1, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like") }

        # Create reactions by organization members
        [org_member1, org_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like") }
        end
      end

      it "does not detect a ring due to organization membership" do
        expect(detector.call).to be false

        # Check that reputation modifiers were not changed
        expect(user.reload.reputation_modifier).to eq(1.0)
        expect(org_member1.reload.reputation_modifier).to eq(1.0)
        expect(org_member2.reload.reputation_modifier).to eq(1.0)
      end
    end

    context "when users have high self-reaction percentage" do
      let(:author1) { create(:user) }
      let(:self_reactor) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target author
        articles_author1 = create_list(:article, 10, user: author1, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like") }

        # Create reactions by self-reactor (mostly to their own articles)
        articles_author1.each { |article| create(:reaction, user: self_reactor, reactable: article, category: "like") }
        
        # Create many self-reactions (more than 30% of total)
        self_articles = create_list(:article, 20, user: self_reactor, published: true)
        self_articles.each { |article| create(:reaction, user: self_reactor, reactable: article, category: "like") }
      end

      it "does not detect a ring due to high self-reaction percentage" do
        expect(detector.call).to be false

        # Check that reputation modifiers were not changed
        expect(user.reload.reputation_modifier).to eq(1.0)
        expect(self_reactor.reload.reputation_modifier).to eq(1.0)
      end
    end
  end
end
