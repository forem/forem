require "rails_helper"

# rubocop:disable Layout/LineLength, Layout/TrailingWhitespace, Style/CombinableLoops
RSpec.describe Spam::ReactionRingDetector, type: :service do
  let(:user) { create(:user, reputation_modifier: 1.0) }
  let(:detector) { described_class.new(user.id) }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article && !options.key?(:tag_list) && !options.key?(:tags) && !options.key?(:with_tags)
      options[:with_tags] = false
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    return Array.new(amount) { create(name, *traits, **options) } if %i[user article].include?(name)

    super
  end

  describe "#call" do
    # Each reaction builds its own article and author unless reactable is given, so a
    # small stubbed threshold avoids creating hundreds of records per example while
    # preserving all concentration (0.8), self-reaction (0.3), and ring-size (3) ratios.
    shared_context "with a small reaction threshold" do
      before { stub_const("#{described_class}::MIN_REACTIONS_THRESHOLD", 5) }
    end

    include_context "with a small reaction threshold"

    let(:gate_author) { create(:user) }

    def create_user_article_reactions(count, created_at: 2.months.ago)
      Array.new(count) do
        article = create(:article, user: gate_author, published: true)
        create(:reaction, user: user, reactable: article, category: "like", created_at: created_at)
      end
    end

    context "when user has insufficient reactions" do
      before do
        # Create fewer reactions than the threshold over 3 months
        create_user_article_reactions(4)
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when user has sufficient reactions but they're too old" do
      before do
        # Create more reactions than the threshold but they're older than 3 months
        create_user_article_reactions(6, created_at: 4.months.ago)
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      before do
        create_user_article_reactions(6)
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when user is trusted" do
      let(:user) { create(:user, :trusted) }

      before do
        create_user_article_reactions(6)
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when no potential ring is found" do
      before do
        # Create enough reactions but no other users with similar patterns
        create_user_article_reactions(6)
      end

      it "returns false" do
        expect(detector.call).to be false
      end
    end

    context "when users have insufficient shared authors" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:insufficient_member) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by insufficient member (only to one author)
        articles_author1.each { |article| create(:reaction, user: insufficient_member, reactable: article, category: "like", created_at: 2.months.ago) }
      end

      it "does not detect a ring due to insufficient shared authors" do
        expect(detector.call).to be false
      end
    end

    context "when users have low concentration of reactions to shared authors" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:author3) { create(:user) }
      let(:low_concentration_member) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)
        articles_author3 = create_list(:article, 3, user: author3, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by low concentration member (mostly to other authors)
        articles_author1.each { |article| create(:reaction, user: low_concentration_member, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: low_concentration_member, reactable: article, category: "like", created_at: 2.months.ago) }
        
        # Add many reactions to other authors (low concentration)
        articles_author3.each { |article| create(:reaction, user: low_concentration_member, reactable: article, category: "like", created_at: 2.months.ago) }
      end

      it "does not detect a ring due to low concentration" do
        expect(detector.call).to be false
      end
    end

    context "when a legitimate reaction ring is detected" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:ring_member1) { create(:user, reputation_modifier: 1.0) }
      let(:ring_member2) { create(:user, reputation_modifier: 1.0) }
      let(:ring_member3) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by the target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user to these authors' articles (focused pattern)
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by ring members to the same authors' articles (coordinated pattern)
        [ring_member1, ring_member2, ring_member3].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
          articles_author2.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
        end

        # Ring members have NO diverse reactions - they only react to the same authors
        # This creates a clear ring pattern
      end

      it "detects the ring and adjusts reputation modifiers", :aggregate_failures do
        expect(detector.call).to be true

        # Check that reputation modifiers were halved (multiplied by 0.5)
        expect(user.reload.reputation_modifier).to eq(0.5)
        expect(ring_member1.reload.reputation_modifier).to eq(0.5)
        expect(ring_member2.reload.reputation_modifier).to eq(0.5)
        expect(ring_member3.reload.reputation_modifier).to eq(0.5)

        # Check that notes were created
        expect(Note.where(noteable: user, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member1, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member2, reason: "reaction_ring_detection")).to exist
        expect(Note.where(noteable: ring_member3, reason: "reaction_ring_detection")).to exist
      end

      it "loads the triggering user's reacted authors, ring members' reacted authors, and member roles without N+1 queries",
         :aggregate_failures do
        member_ids = [ring_member1, ring_member2, ring_member3].map(&:id)
        reacted_author_queries = 0
        member_plucks = Hash.new(0)
        member_reaction_queries = 0
        member_role_counts = 0

        callback = lambda do |*, payload|
          sql = payload[:sql]
          binds = payload[:type_casted_binds]
          binds = Array(binds.respond_to?(:call) ? binds.call : binds)

          if sql.include?('SELECT COUNT(*) FROM "roles"')
            member_role_counts += 1 if member_ids.any? do |id|
              binds.include?(id) || sql.match?(/"users_roles"\."user_id" = #{id}\b/)
            end
            next
          end

          next unless sql.include?('FROM "reactions"')
          next unless sql.include?("JOIN articles ON reactions.reactable_id = articles.id")

          # Only the reactions-rooted pluck; the similar-patterns query is
          # rooted at users and also binds the triggering user's id.
          if sql.include?('"reactions"."user_id" =') &&
              (binds.include?(user.id) || sql.match?(/"reactions"\."user_id" = #{user.id}\b/))
            reacted_author_queries += 1
          end

          matched_member = false
          member_ids.each do |id|
            next unless binds.include?(id) || sql.match?(/"reactions"\."user_id" (?:=|IN \([^)]*)\s*#{id}\b/)

            member_plucks[id] += 1
            matched_member = true
          end
          member_reaction_queries += 1 if matched_member
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          expect(detector.call).to be true
        end

        expect(reacted_author_queries).to eq(1)
        expect(member_plucks.values_at(*member_ids)).to eq([1, 1, 1])
        expect(member_reaction_queries).to eq(1)
        expect(member_role_counts).to eq(0)
      end

      it "still skips ring members who are admins" do
        ring_member3.add_role(:admin)

        # The two remaining members fall below the minimum ring size
        expect(detector.call).to be false
        expect(ring_member1.reload.reputation_modifier).to eq(1.0)
        expect(ring_member3.reload.reputation_modifier).to eq(1.0)
      end
    end

    context "when users have legitimate community connections" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:legitimate_member1) { create(:user, reputation_modifier: 1.0) }
      let(:legitimate_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by legitimate members
        [legitimate_member1, legitimate_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
          articles_author2.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
        end

        # Create legitimate connections (following relationships)
        user.follow(legitimate_member1)
        user.follow(legitimate_member2)

        # Add diverse reactions to show legitimate community behavior
        other_authors = create_list(:user, 3)
        other_authors.each do |other_author|
          other_article = create(:article, user: other_author, published: true)
          create(:reaction, user: legitimate_member1, reactable: other_article, category: "like", created_at: 2.months.ago)
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
      let(:org_member1) { create(:user, reputation_modifier: 1.0) }
      let(:org_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Add all users to the same organization
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create(:organization_membership, user: org_member1, organization: organization, type_of_user: "member")
        create(:organization_membership, user: org_member2, organization: organization, type_of_user: "member")

        # Create articles by target author
        articles_author1 = create_list(:article, 6, user: author1, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by organization members
        [org_member1, org_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
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
        articles_author1 = create_list(:article, 6, user: author1, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by self-reactor (mostly to their own articles)
        articles_author1.each { |article| create(:reaction, user: self_reactor, reactable: article, category: "like", created_at: 2.months.ago) }
        
        # Create many self-reactions (more than 30% of total)
        self_articles = create_list(:article, 3, user: self_reactor, published: true)
        self_articles.each { |article| create(:reaction, user: self_reactor, reactable: article, category: "like", created_at: 2.months.ago) }
      end

      it "does not detect a ring due to high self-reaction percentage" do
        expect(detector.call).to be false

        # Check that reputation modifiers were not changed
        expect(user.reload.reputation_modifier).to eq(1.0)
        expect(self_reactor.reload.reputation_modifier).to eq(1.0)
      end
    end

    context "when ring size is below minimum threshold" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:single_member) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by only one member (below minimum ring size of 3)
        articles_author1.each { |article| create(:reaction, user: single_member, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: single_member, reactable: article, category: "like", created_at: 2.months.ago) }
      end

      it "does not detect a ring due to insufficient ring size" do
        expect(detector.call).to be false
      end
    end

    context "when users have mixed reaction patterns over time" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:author3) { create(:user) }
      let(:mixed_pattern_member) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)
        articles_author3 = create_list(:article, 2, user: author3, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by mixed pattern member (some to shared authors, some to others)
        articles_author1.each { |article| create(:reaction, user: mixed_pattern_member, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: mixed_pattern_member, reactable: article, category: "like", created_at: 2.months.ago) }
        
        # Add reactions to other authors to show diverse patterns
        articles_author3.each { |article| create(:reaction, user: mixed_pattern_member, reactable: article, category: "like", created_at: 2.months.ago) }
        
        # Add reactions to even more diverse authors
        other_authors = create_list(:user, 2)
        other_authors.each do |other_author|
          other_article = create(:article, user: other_author, published: true)
          create(:reaction, user: mixed_pattern_member, reactable: other_article, category: "like", created_at: 2.months.ago)
        end
      end

      it "does not detect a ring due to diverse reaction patterns" do
        expect(detector.call).to be false
      end
    end

    context "when users have legitimate temporal patterns" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:temporal_member) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by temporal member (spread over time, not coordinated)
        articles_author1.each_with_index do |article, index|
          create(:reaction, user: temporal_member, reactable: article, category: "like", created_at: (2.months.ago + index.days))
        end
        articles_author2.each_with_index do |article, index|
          create(:reaction, user: temporal_member, reactable: article, category: "like", created_at: (2.months.ago + (index + 5).days))
        end

        # Add diverse reactions to other authors over time
        other_authors = create_list(:user, 3)
        other_authors.each_with_index do |other_author, author_index|
          other_article = create(:article, user: other_author, published: true)
          offset_days = author_index * 10
          create(:reaction, user: temporal_member, reactable: other_article, category: "like",
                            created_at: 2.months.ago + offset_days.days)
        end
      end

      it "does not detect a ring due to legitimate temporal patterns" do
        expect(detector.call).to be false
      end
    end

    context "when users have legitimate community connections but no ring behavior" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:community_member1) { create(:user, reputation_modifier: 1.0) }
      let(:community_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by community members (some overlap, but not coordinated)
        articles_author1.each { |article| create(:reaction, user: community_member1, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: community_member2, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create legitimate community connections
        user.follow(community_member1)
        community_member1.follow(user)
        user.follow(community_member2)
        community_member2.follow(user)

        # Add diverse reactions to show legitimate community behavior
        other_authors = create_list(:user, 3)
        other_authors.each do |other_author|
          other_article = create(:article, user: other_author, published: true)
          create(:reaction, user: community_member1, reactable: other_article, category: "like", created_at: 2.months.ago)
        end
      end

      it "does not detect a ring due to legitimate community connections" do
        expect(detector.call).to be false
      end
    end

    context "when users have legitimate organization connections" do
      let(:organization) { create(:organization) }
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let(:org_member1) { create(:user, reputation_modifier: 1.0) }
      let(:org_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Add all users to the same organization
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create(:organization_membership, user: org_member1, organization: organization, type_of_user: "member")
        create(:organization_membership, user: org_member2, organization: organization, type_of_user: "member")

        # Create articles by target authors
        articles_author1 = create_list(:article, 3, user: author1, published: true)
        articles_author2 = create_list(:article, 3, user: author2, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }
        articles_author2.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by organization members
        [org_member1, org_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
          articles_author2.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
        end

        # Add diverse reactions to show legitimate organization behavior
        other_authors = create_list(:user, 3)
        other_authors.each do |other_author|
          other_article = create(:article, user: other_author, published: true)
          create(:reaction, user: org_member1, reactable: other_article, category: "like", created_at: 2.months.ago)
        end
      end

      it "does not detect a ring due to organization membership" do
        expect(detector.call).to be false
      end
    end

    context "when users share multiple organizations" do
      let(:organization1) { create(:organization) }
      let(:organization2) { create(:organization) }
      let(:author1) { create(:user) }
      let(:org_member1) { create(:user, reputation_modifier: 1.0) }
      let(:org_member2) { create(:user, reputation_modifier: 1.0) }

      before do
        # Add users to multiple organizations, with some overlap
        create(:organization_membership, user: user, organization: organization1, type_of_user: "member")
        create(:organization_membership, user: user, organization: organization2, type_of_user: "member")
        
        create(:organization_membership, user: org_member1, organization: organization1, type_of_user: "member")
        create(:organization_membership, user: org_member1, organization: organization2, type_of_user: "member")
        
        create(:organization_membership, user: org_member2, organization: organization1, type_of_user: "member")
        # org_member2 is only in organization1, not organization2

        # Create articles by target author
        articles_author1 = create_list(:article, 6, user: author1, published: true)

        # Create reactions by the main user
        articles_author1.each { |article| create(:reaction, user: user, reactable: article, category: "like", created_at: 2.months.ago) }

        # Create reactions by organization members
        [org_member1, org_member2].each do |member|
          articles_author1.each { |article| create(:reaction, user: member, reactable: article, category: "like", created_at: 2.months.ago) }
        end
      end

      it "does not detect a ring due to shared organization membership" do
        expect(detector.call).to be false

        # Check that reputation modifiers were not changed
        expect(user.reload.reputation_modifier).to eq(1.0)
        expect(org_member1.reload.reputation_modifier).to eq(1.0)
        expect(org_member2.reload.reputation_modifier).to eq(1.0)
      end
    end
  end
end
# rubocop:enable Layout/LineLength, Layout/TrailingWhitespace, Style/CombinableLoops
