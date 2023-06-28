# Reaction uses this class to calculate points before saving
class CalculateReactionPoints
  DEFAULT_SCORE = 1.0

  POINTS = {
    "invalid" => 0,
    "User" => 2,
    "confirmed" => 2,
    "positive" => 5,
    "negative" => -5
  }.freeze

  # Days to ramp up new user points weight
  NEW_USER_RAMPUP_DAYS_COUNT = 10

  def self.call(reaction)
    new(reaction).calculate_points
  end

  def initialize(reaction)
    @reaction = reaction
  end

  def calculate_points
    base_points = reaction_category_score

    # Adjust for certain states
    base_points = POINTS["invalid"] if status == "invalid"
    base_points /= POINTS["User"] if reactable_type == "User"
    base_points *= POINTS["confirmed"] if status == "confirmed"

    unless persisted? # Actions we only want to apply upon initial creation
      # Author's comment reaction counts for more weight on to their own posts. (5.0 vs 1.0)
      base_points *= POINTS["positive"] if positive_reaction_to_comment_on_own_article?

      # New users will have their reaction weight gradually ramp by 0.1 from 0 to 1.0.
      base_points *= new_user_adjusted_points if new_untrusted_user # New users get minimal reaction weight
    end

    user ? (base_points * user.reputation_modifier) : POINTS["negative"]
  end

  attr_reader :reaction

  delegate :category, :persisted?, :positive?, :reactable, :reactable_type, :status, :user, :user_id,
           to: :reaction

  private

  def reaction_category
    ReactionCategory[category]
  end

  def reaction_category_score
    reaction_category&.score || DEFAULT_SCORE
  end

  def new_untrusted_user
    user.registered_at > NEW_USER_RAMPUP_DAYS_COUNT.days.ago && !user.trusted? && !user.any_admin?
  end

  def new_user_adjusted_points
    ((Time.current - user.registered_at).seconds.in_days / NEW_USER_RAMPUP_DAYS_COUNT)
  end

  def positive_reaction_to_comment_on_own_article?
    positive? && reaction_to_comment? && own_article?
  end

  def reaction_to_comment?
    reactable_type == "Comment"
  end

  def own_article?
    reactable&.commentable&.user_id == user_id
  end
end
