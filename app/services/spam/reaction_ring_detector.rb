# frozen_string_literal: true

module Spam
  # Detects reaction rings where multiple users consistently react to the same authors
  # without reacting to other authors, indicating coordinated behavior.
  class ReactionRingDetector
    # Minimum number of article reactions in the past 3 months to trigger analysis
    MIN_REACTIONS_THRESHOLD = 50

    # Minimum number of users in a potential ring
    MIN_RING_SIZE = 3

    # Minimum percentage of reactions that must be to the same authors to be suspicious
    MIN_AUTHOR_CONCENTRATION = 0.8

    # Minimum number of shared authors between ring members
    MIN_SHARED_AUTHORS = 2

    # Maximum percentage of self-reactions allowed (users reacting to their own articles)
    MAX_SELF_REACTION_PERCENTAGE = 0.3

    def initialize(user_id)
      @user_id = user_id
      @user = User.find(user_id)
    end

    def call
      return false unless should_analyze_user?

      potential_ring = find_potential_ring
      return false if potential_ring.empty?

      return false unless is_legitimate_ring?(potential_ring)

      # Apply reputation modifier adjustment to all users in the ring
      adjust_reputation_for_ring(potential_ring)
      true
    end

    private

    attr_reader :user_id, :user

    def should_analyze_user?
      return false if user.any_admin? || user.super_moderator?
      return false if user.trusted?

      # Check if user has enough reactions in the past 3 months
      recent_reactions_count >= MIN_REACTIONS_THRESHOLD
    end

    def recent_reactions_count
      @recent_reactions_count ||= user.reactions
                                    .public_category
                                    .only_articles
                                    .where(created_at: 3.months.ago..)
                                    .count
    end

    def find_potential_ring
      # Get users who have reacted to articles by the same authors as our user
      shared_authors = find_shared_authors
      return [] if shared_authors.empty?

      # Find users who have high overlap with our user's reaction patterns
      potential_ring_members = find_users_with_similar_patterns(shared_authors)
      
      # Filter to only include users who meet the ring criteria
      potential_ring_members.select do |member|
        meets_ring_criteria?(member, shared_authors)
      end
    end

    def find_shared_authors
      # Get authors of articles that our user has reacted to in the past 3 months
      user_reacted_article_authors = user.reactions
                                        .public_category
                                        .only_articles
                                        .where(created_at: 3.months.ago..)
                                        .joins("JOIN articles ON reactions.reactable_id = articles.id")
                                        .pluck("articles.user_id")
                                        .uniq

      # Exclude self-reactions (user reacting to their own articles)
      user_reacted_article_authors - [user_id]
    end

    def find_users_with_similar_patterns(shared_authors)
      # Find users who have reacted to articles by the same authors
      User.joins(:reactions)
          .joins("JOIN articles ON reactions.reactable_id = articles.id")
          .where(reactions: { 
            reactable_type: "Article",
            category: ReactionCategory.public.map(&:to_s),
            created_at: 3.months.ago..
          })
          .where("articles.user_id IN (?)", shared_authors)
          .where.not(id: user_id)
          .group("users.id")
          .having("COUNT(DISTINCT articles.user_id) >= ?", MIN_SHARED_AUTHORS)
          .select("users.id, COUNT(DISTINCT articles.user_id) as shared_author_count")
    end

    def meets_ring_criteria?(member, shared_authors)
      member_user = User.find(member.id)
      
      # Skip admin and trusted users
      return false if member_user.any_admin? || member_user.trusted?
      
      # Get this member's recent reactions
      member_reactions = member_user.reactions
                                   .public_category
                                   .only_articles
                                   .where(created_at: 3.months.ago..)
                                   .joins("JOIN articles ON reactions.reactable_id = articles.id")
                                   .pluck("articles.user_id")

      # Calculate concentration of reactions to shared authors
      shared_author_reactions = member_reactions.count { |author_id| shared_authors.include?(author_id) }
      total_reactions = member_reactions.size
      
      return false if total_reactions < MIN_REACTIONS_THRESHOLD

      # Check if concentration is suspiciously high
      concentration = shared_author_reactions.to_f / total_reactions
      return false if concentration < MIN_AUTHOR_CONCENTRATION

      # Check self-reaction percentage (should not be too high)
      self_reactions = member_reactions.count { |author_id| author_id == member.id }
      self_reaction_percentage = self_reactions.to_f / total_reactions
      return false if self_reaction_percentage > MAX_SELF_REACTION_PERCENTAGE

      true
    end

    def is_legitimate_ring?(potential_ring)
      return false if potential_ring.size < MIN_RING_SIZE

      # Additional validation: check if the ring members have diverse reaction patterns
      # outside of the shared authors (to avoid false positives from legitimate communities)
      has_diverse_patterns = potential_ring.any? do |member|
        member_user = User.find(member.id)
        all_authors = member_user.reactions
                                .public_category
                                .only_articles
                                .where(created_at: 3.months.ago..)
                                .joins("JOIN articles ON reactions.reactable_id = articles.id")
                                .pluck("articles.user_id")
                                .uniq

        # Check if they react to authors outside the shared group
        shared_authors = find_shared_authors
        (all_authors - shared_authors - [member.id]).size > 2
      end

      # If most members have diverse patterns, it's likely a legitimate community
      # If they don't have diverse patterns, it's likely a ring
      !has_diverse_patterns || validate_ring_legitimacy(potential_ring)
    end

    def validate_ring_legitimacy(potential_ring)
      # Additional checks to avoid false positives:
      # 1. Check if users are from the same organization (legitimate)
      # 2. Check if they follow each other (legitimate community)
      # 3. Check temporal patterns (suspicious if all reactions happen in bursts)
      
      shared_authors = find_shared_authors
      
      # Check for legitimate community indicators
      legitimate_indicators = potential_ring.count do |member|
        member_user = User.find(member.id)
        
        # Check if they follow the original user or are followed by them
        follows_original = member_user.following_users.exists?(id: user_id)
        followed_by_original = user.following_users.exists?(id: member_user.id)
        
        # Check if they're in the same organization (users can belong to multiple orgs)
        same_organization = user.organizations.exists? && 
                           member_user.organizations.exists? && 
                           (user.organizations & member_user.organizations).any?
        
        follows_original || followed_by_original || same_organization
      end

      # If most members have legitimate connections, it's probably not a ring
      legitimate_indicators < (potential_ring.size * 0.5)
    end

    def adjust_reputation_for_ring(ring_members)
      ring_members.each do |member|
        member_user = User.find(member.id)
        
        # Halve reputation modifier for ring members (multiply by 0.5)
        new_modifier = (member_user.reputation_modifier * 0.5).round(2)
        member_user.update!(reputation_modifier: new_modifier)
        
        # Log the action for audit purposes
        Note.create!(
          author_id: user_id, # Using the triggering user as author for now
          noteable_id: member_user.id,
          noteable_type: "User",
          reason: "reaction_ring_detection",
          content: "User detected as part of reaction ring. Reputation modifier halved to #{new_modifier}."
        )
      end

      # Also adjust the original user
      new_modifier = (user.reputation_modifier * 0.5).round(2)
      user.update!(reputation_modifier: new_modifier)
      Note.create!(
        author_id: user_id,
        noteable_id: user_id,
        noteable_type: "User", 
        reason: "reaction_ring_detection",
        content: "User detected as part of reaction ring. Reputation modifier halved to #{new_modifier}."
      )
    end
  end
end
