class Stories::FeedsController < ApplicationController
  respond_to :json

  VARIANTS = {
    "more_random_experiment" => :default_home_feed_with_more_randomness_experiment,
    "mix_base_more_random_experiment" => :mix_default_and_more_random_experiment,
    "more_tag_weight_experiment" => :more_tag_weight_experiment,
    "more_tag_weight_more_random_experiment" => :more_tag_weight_more_random_experiment,
    "more_comments_experiment" => :more_comments_experiment,
    "more_experience_level_weight_experiment" => :more_experience_level_weight_experiment,
    "more_tag_weight_randomized_at_end_experiment" => :more_tag_weight_randomized_at_end_experiment,
    "more_experience_level_weight_randomized_at_end_experiment" =>
      :more_experience_level_weight_randomized_at_end_experiment,
    "more_comments_randomized_at_end_experiment" => :more_comments_randomized_at_end_experiment,
    "more_comments_medium_weight_randomized_at_end_experiment" =>
      :more_comments_medium_weight_randomized_at_end_experiment,
    "more_comments_minimal_weight_randomized_at_end_experiment" =>
      :more_comments_minimal_weight_randomized_at_end_experiment,
    "mix_of_everything_experiment" => :mix_of_everything_experiment
  }.freeze

  def show
    @stories = assign_feed_stories
  end

  private

  def assign_feed_stories
    feed = Articles::Feed.new(user: current_user, page: @page, tag: params[:tag])
    stories = if params[:timeframe].in?(Timeframer::FILTER_TIMEFRAMES)
                feed.top_articles_by_timeframe(timeframe: params[:timeframe])
              elsif params[:timeframe] == Timeframer::LATEST_TIMEFRAME
                feed.latest_feed
              elsif user_signed_in?
                ab_test_user_signed_in_feed(feed)
              else
                feed.default_home_feed(user_signed_in: user_signed_in?)
              end
    ArticleDecorator.decorate_collection(stories)
  end

  def ab_test_user_signed_in_feed(feed)
    test_variant = field_test(:user_home_feed, participant: current_user)
    Honeycomb.add_field("field_test_user_home_feed", test_variant) # Monitoring different variants

    if VARIANTS[test_variant].nil? || test_variant == "base"
      feed.default_home_feed(user_signed_in: true)
    else
      feed.public_send(VARIANTS[test_variant])
    end
  end
end
