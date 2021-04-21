# Helpers for controllers interacting with Listing
module ListingsToolkit
  extend ActiveSupport::Concern

  MANDATORY_FIELDS_FOR_UPDATE = %i[body_markdown title tag_list].freeze

  def unpublish_listing
    @listing.update(published: false)
  end

  def publish_listing
    @listing.update(published: true)
  end

  def update_listing_details
    # [@forem/oss] Not entirely sure what the intention behind the
    # original code was, but at least this is more compact.

    # [@forem/oss] Rails 6.1 adds `.compact` on ActionController::Parameters
    # rubocop:disable Style/CollectionCompact
    filtered_params = listing_params.reject { |_k, v| v.nil? }
    # rubocop:enable Style/CollectionCompact

    @listing.update(filtered_params)
  end

  def bump_listing_success
    @listing.update(bumped_at: Time.current)
  end

  def clear_listings_cache
    Listings::BustCacheWorker.perform_async(@listing.id)
  end

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def create
    @listing = Listing.new(listing_params)
    organization_id = @listing.organization_id

    # this will 401 for now if they don't belong in the org
    authorize @listing, :authorized_organization_poster? if organization_id.present?

    @listing.user_id = current_user.id
    org = Organization.find_by(id: organization_id)

    if listing_params[:action] == "draft"
      create_draft
      return
    end

    unless @listing.valid?
      @credits = current_user.credits.unspent
      process_unsuccessful_creation
      return
    end

    cost = @listing.cost
    # we use the org's credits if available, otherwise we default to the user's
    if org&.enough_credits?(cost)
      create_listing(org, cost)
    elsif current_user.enough_credits?(cost)
      create_listing(current_user, cost)
    else
      process_no_credit_left
    end
  end

  ALLOWED_PARAMS = %i[
    title body_markdown listing_category_id tag_list
    expires_at contact_via_connect location organization_id action
  ].freeze

  # Filter for a set of known safe params
  def listing_params
    tags = params["listing"].delete("tags")
    if tags.present?
      params["listing"]["tag_list"] = tags.join(", ")
    end
    params.require(:listing).permit(ALLOWED_PARAMS)
  end

  def create_draft
    @listing.published = false
    if @listing.save
      process_successful_draft
    else
      @credits = current_user.credits.unspent
      @listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      process_unsuccessful_draft
    end
  end

  def create_listing(purchaser, cost)
    successful_transaction = false
    ActiveRecord::Base.transaction do
      # subtract credits
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @listing,
        cost: cost,
      )

      # save the listing
      @listing.bumped_at = Time.current
      @listing.published = true
      @listing.originally_published_at = Time.current

      # since we can't raise active record errors in this transaction
      # due to the fact that we need to display them in the :new view,
      # we manually rollback the transaction if there are validation errors
      raise ActiveRecord::Rollback unless @listing.save

      successful_transaction = true
    end

    if successful_transaction
      rate_limiter.track_limit_by_action(:listing_creation)
      clear_listings_cache
      process_successful_creation
    else
      @credits = current_user.credits.unspent
      @listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      process_unsuccessful_creation
    end
  end

  def update
    authorize @listing

    cost = @listing.cost

    # NOTE: this should probably be split in three different actions: bump, unpublish, publish
    return bump_listing(cost) if listing_params[:action] == "bump"

    if listing_params[:action] == "unpublish"
      unpublish_listing
      process_after_unpublish
      return
    elsif listing_params[:action] == "publish"
      unless @listing.bumped_at?
        first_publish(cost)
        return
      end

      publish_listing
    elsif listing_updatable?
      saved = update_listing_details
      return process_unsuccessful_update unless saved
    end

    clear_listings_cache
    process_after_update
  end

  def bump_listing(cost)
    org = Organization.find_by(id: @listing.organization_id)

    if org&.enough_credits?(cost)
      charge_credits_before_bump(org, cost)
    elsif current_user.enough_credits?(cost)
      charge_credits_before_bump(current_user, cost)
    else
      process_no_credit_left && return
    end
  end

  def charge_credits_before_bump(purchaser, cost)
    ActiveRecord::Base.transaction do
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @listing,
        cost: cost,
      )

      raise ActiveRecord::Rollback unless bump_listing_success
    end
  end

  def first_publish(cost)
    author = @listing.author
    available_user_credits = author.is_a?(Organization) ? current_user.credits.unspent.size : 0

    if author.credits.unspent.size >= cost
      create_listing(author, cost)
    elsif available_user_credits >= cost
      create_listing(current_user, cost)
    else
      process_no_credit_left
    end
  end

  def listing_updatable?
    at_least_one_param_present? && (bumped_in_last_24_hrs? || !@listing.published)
  end

  def at_least_one_param_present?
    MANDATORY_FIELDS_FOR_UPDATE.any? { |field| listing_params.include?(field) }
  end

  def bumped_in_last_24_hrs?
    return unless (last_bumped_at = @listing.bumped_at)

    last_bumped_at > 24.hours.ago
  end
end
