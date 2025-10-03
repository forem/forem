##
# Service to handle reassigning articles to more appropriate subforems
# when they are marked as offtopic for their current subforem.
class SubforemReassignmentService
  OFFTOPIC_LABELS = %w[
    ok_but_offtopic_for_subforem
    very_good_but_offtopic_for_subforem
    great_but_off_topic_for_subforem
  ].freeze

  # Mapping from offtopic labels to their on-topic equivalents
  OFFTopic_TO_ON_TOPIC_MAPPING = {
    "ok_but_offtopic_for_subforem" => "okay_and_on_topic",
    "very_good_but_offtopic_for_subforem" => "very_good_and_on_topic",
    "great_but_off_topic_for_subforem" => "great_and_on_topic"
  }.freeze

  def initialize(article)
    @article = article
  end

  ##
  # Checks if the article should be reassigned to a different subforem
  # and performs the reassignment if appropriate.
  #
  # @return [Boolean] true if reassignment occurred, false otherwise
  def check_and_reassign
    return false unless should_reassign?

    new_subforem_id = find_appropriate_subforem
    return false unless new_subforem_id

    perform_reassignment(new_subforem_id)
    true
  end

  private

  attr_reader :article

  ##
  # Determines if the article should be reassigned based on its automod label.
  #
  # @return [Boolean] true if the article has an offtopic label, is not spam, and user allows reassignment
  def should_reassign?
    OFFTOPIC_LABELS.include?(article.automod_label) && 
      !spam_label? && 
      user_allows_reassignment?
  end

  ##
  # Determines if the article has a spam-related automod label.
  #
  # @return [Boolean] true if the article is marked as spam
  def spam_label?
    %w[
      clear_and_obvious_spam
      likely_spam
      clear_and_obvious_harmful
      likely_harmful
      clear_and_obvious_inciting
      likely_inciting
      clear_and_obvious_low_quality
      likely_low_quality
    ].include?(article.automod_label)
  end

  ##
  # Checks if the user allows automatic subforem reassignment.
  #
  # @return [Boolean] true if the user allows reassignment, false otherwise
  def user_allows_reassignment?
    article.user&.setting&.disallow_subforem_reassignment != true
  end

  ##
  # Gets the on-topic equivalent of the current offtopic automod label.
  #
  # @return [String, nil] the on-topic label equivalent, or nil if no mapping exists
  def on_topic_equivalent_label
    OFFTopic_TO_ON_TOPIC_MAPPING[article.automod_label]
  end

  ##
  # Uses AI to find the most appropriate subforem for the article.
  #
  # @return [Integer, nil] the ID of the most appropriate subforem, or nil if none found
  def find_appropriate_subforem
    begin
      finder = Ai::SubforemFinder.new(article)
      finder.find_appropriate_subforem
    rescue StandardError => e
      Rails.logger.error("Failed to find appropriate subforem for article #{article.id}: #{e}")
      nil
    end
  end

  ##
  # Performs the actual reassignment and sends notification.
  #
  # @param new_subforem_id [Integer] the ID of the new subforem
  def perform_reassignment(new_subforem_id)
    old_subforem_id = article.subforem_id
    new_subforem = Subforem.find(new_subforem_id)

    # Update both subforem and automod label
    update_attributes = { subforem_id: new_subforem_id }
    
    # Update automod label to on-topic equivalent if available
    if on_topic_equivalent_label
      update_attributes[:automod_label] = on_topic_equivalent_label
    end

    article.update!(update_attributes)

    # Send notification about the subforem change
    send_subforem_change_notification(old_subforem_id, new_subforem_id)

    Rails.logger.info("Article #{article.id} reassigned from subforem #{old_subforem_id} to #{new_subforem_id}" \
                     "#{on_topic_equivalent_label ? " and automod label updated to #{on_topic_equivalent_label}" : ""}")
  end

  ##
  # Sends a notification to the article author about the subforem change.
  #
  # @param old_subforem_id [Integer, nil] the ID of the previous subforem
  # @param new_subforem_id [Integer] the ID of the new subforem
  def send_subforem_change_notification(old_subforem_id, new_subforem_id)
    Notifications::SubforemChangeNotificationWorker.perform_async(
      article.id,
      old_subforem_id,
      new_subforem_id,
    )
  end
end
