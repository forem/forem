module Admin
  class LinkedDomainsController < Admin::ApplicationController
    layout "admin"

    # Typical score of a post by an author with the spam role (see Article#update_score).
    SPAM_POST_SCORE = 500
    EXAMPLE_AUTHOR_SCORES = [0, 10, 20, 50].freeze
    OVER_THRESHOLD_COUNT_CACHE_TTL = 5.minutes
    INDEX_COLUMNS = %i[id host net_score manual_setting created_at].freeze

    def index
      @linked_domains = LinkedDomain
        .select(*INDEX_COLUMNS)
        .order(id: :desc)
        .page(params[:page])
        .per(20)
        .without_count
      @spam_score_threshold = ::Settings::RateLimit.linked_domain_spam_score_threshold
      @spam_post_score = SPAM_POST_SCORE
      @threshold_examples = EXAMPLE_AUTHOR_SCORES.map do |author_score|
        [author_score, Spam::Handler.linked_domain_spam_net_score_threshold(author_score)]
      end
      @domains_over_threshold_count = Rails.cache.fetch(
        over_threshold_count_cache_key(@spam_score_threshold),
        expires_in: OVER_THRESHOLD_COUNT_CACHE_TTL,
      ) do
        LinkedDomain.where(net_score: ..-@spam_score_threshold).count
      end
    end

    def update_spam_threshold
      threshold = Integer(params[:linked_domain_spam_score_threshold].to_s, 10, exception: false)
      unless threshold
        redirect_to admin_linked_domains_path, alert: "Threshold must be a whole number."
        return
      end

      result = ::Settings::Upsert.call({ linked_domain_spam_score_threshold: threshold.to_s }, ::Settings::RateLimit)

      if result.success?
        Rails.cache.delete(over_threshold_count_cache_key(threshold))
        Audit::Logger.log(:internal, current_user, params.dup)
        redirect_to admin_linked_domains_path, notice: "Domain abuse score threshold updated."
      else
        redirect_to admin_linked_domains_path, alert: result.errors.to_sentence
      end
    end

    def edit
      @linked_domain = LinkedDomain.find(params[:id])
    end

    def update
      @linked_domain = LinkedDomain.find(params[:id])

      if @linked_domain.update(linked_domain_params)
        Rails.cache.delete(over_threshold_count_cache_key(::Settings::RateLimit.linked_domain_spam_score_threshold))
        redirect_to admin_linked_domains_path, notice: "Linked domain was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def over_threshold_count_cache_key(threshold)
      "admin/linked_domains/over_threshold_count/#{threshold}"
    end

    def linked_domain_params
      params.require(:linked_domain).permit(:manual_setting)
    end
  end
end
