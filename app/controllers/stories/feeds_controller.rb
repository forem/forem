module Stories
  class FeedsController < ApplicationController
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
      stories = if params[:timeframe].in?(Timeframer::FILTER_TIMEFRAMES)
                  timeframe_feed
                elsif params[:timeframe] == Timeframer::LATEST_TIMEFRAME
                  latest_feed
                elsif user_signed_in?
                  signed_in_base_feed
                else
                  signed_out_base_feed
                end
      ArticleDecorator.decorate_collection(stories)
    end

    def signed_in_base_feed
      if SiteConfig.feed_strategy == "basic"
        Articles::Feeds::Basic.new(user: current_user, page: @page, tag: params[:tag]).feed
      else
        optimized_signed_in_feed
      end
    end

    def signed_out_base_feed
      if SiteConfig.feed_strategy == "basic"
        Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag]).feed
      else
        Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
          .default_home_feed(user_signed_in: user_signed_in?)
      end
    end

    def timeframe_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      feed.top_articles_by_timeframe(timeframe: params[:timeframe])
    end

    def latest_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      feed.latest_feed
    end

    def optimized_signed_in_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      test_variant = field_test(:user_home_feed, participant: current_user)
      Honeycomb.add_field("field_test_user_home_feed", test_variant) # Monitoring different variants
      if VARIANTS[test_variant].nil? || test_variant == "base"
        feed.default_home_feed(user_signed_in: true)
      else
        feed.public_send(VARIANTS[test_variant])
      end
    end
  end
end
