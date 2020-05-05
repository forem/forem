module ClassifiedListingsToolkit
  extend ActiveSupport::Concern

  MANDATORY_FIELDS_FOR_UPDATE = %i[body_markdown title tag_list].freeze

  def unpublish_listing
    @classified_listing.update(published: false)
  end

  def publish_listing
    @classified_listing.update(published: true)
  end

  def update_listing_details
    # [thepracticaldev/oss] Not entirely sure what the intention behind the
    # original code was, but at least this is more compact.
    filtered_params = listing_params.reject { |_k, v| v.nil? }
    @classified_listing.update(filtered_params)
  end

  def bump_listing_success
    @classified_listing.update(bumped_at: Time.current)
  end

  def clear_listings_cache
    ClassifiedListings::BustCacheWorker.perform_async(@classified_listing.id)
  end

  def set_classified_listing
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  def create
    @classified_listing = ClassifiedListing.new(listing_params)

    # this will 401 for now if they don't belong in the org
    authorize @classified_listing, :authorized_organization_poster? if @classified_listing.organization_id.present?

    @classified_listing.user_id = current_user.id
    org = Organization.find_by(id: @classified_listing.organization_id)

    if listing_params[:action] == "draft"
      create_draft
      return
    end

    available_org_credits = org.credits.unspent if org
    available_user_credits = current_user.credits.unspent

    unless @classified_listing.valid?
      @credits = current_user.credits.unspent
      process_unsuccessful_creation
      return
    end

    cost = @classified_listing.cost
    # we use the org's credits if available, otherwise we default to the user's
    if org && available_org_credits.size >= cost
      create_listing(org, cost)
    elsif available_user_credits.size >= cost
      create_listing(current_user, cost)
    else
      process_no_credit_left
    end
  end

  ALLOWED_PARAMS = %i[
    title body_markdown classified_listing_category_id tag_list
    expires_at contact_via_connect location organization_id action
  ].freeze

  # Filter for a set of known safe params
  def listing_params
    tags = params["classified_listing"].delete("tags")
    if tags.present?
      params["classified_listing"]["tag_list"] = tags.join(", ")
    end
    params.require(:classified_listing).permit(ALLOWED_PARAMS)
  end

  def create_draft
    @classified_listing.published = false
    if @classified_listing.save
      process_successful_draft
    else
      @credits = current_user.credits.unspent
      @classified_listing.cached_tag_list = listing_params[:tag_list]
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
        purchase: @classified_listing,
        cost: cost,
      )

      # save the listing
      @classified_listing.bumped_at = Time.current
      @classified_listing.published = true

      # since we can't raise active record errors in this transaction
      # due to the fact that we need to display them in the :new view,
      # we manually rollback the transaction if there are validation errors
      raise ActiveRecord::Rollback unless @classified_listing.save

      successful_transaction = true
    end

    if successful_transaction
      clear_listings_cache
      process_successful_creation
    else
      @credits = current_user.credits.unspent
      @classified_listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      process_unsuccessful_creation
    end
  end

  def update
    authorize @classified_listing

    cost = @classified_listing.cost

    # NOTE: this should probably be split in three different actions: bump, unpublish, publish
    return bump_listing(cost) if listing_params[:action] == "bump"

    if listing_params[:action] == "unpublish"
      unpublish_listing
      process_after_unpublish
      return
    elsif listing_params[:action] == "publish"
      unless @classified_listing.bumped_at?
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
    org = Organization.find_by(id: @classified_listing.organization_id)

    available_org_credits = org.credits.unspent if org
    available_user_credits = current_user.credits.unspent

    if org && available_org_credits.size >= cost
      charge_credits_before_bump(org, cost)
    elsif available_user_credits.size >= cost
      charge_credits_before_bump(current_user, cost)
    else
      process_no_credit_left && return
    end
  end

  def charge_credits_before_bump(purchaser, cost)
    ActiveRecord::Base.transaction do
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @classified_listing,
        cost: cost,
      )

      raise ActiveRecord::Rollback unless bump_listing_success
    end
  end

  def first_publish(cost)
    available_author_credits = @classified_listing.author.credits.unspent
    available_user_credits = []
    if @classified_listing.author.is_a?(Organization)
      available_user_credits = current_user.credits.unspent
    end

    if available_author_credits.size >= cost
      create_listing(@classified_listing.author, cost)
    elsif available_user_credits.size >= cost
      create_listing(current_user, cost)
    else
      process_no_credit_left
    end
  end

  def listing_updatable?
    at_least_one_param_present? && (bumped_in_last_24_hrs? || !@classified_listing.published)
  end

  def at_least_one_param_present?
    MANDATORY_FIELDS_FOR_UPDATE.any? { |i| listing_params.include? i }
  end

  def bumped_in_last_24_hrs?
    @classified_listing.bumped_at && @classified_listing.bumped_at > 24.hours.ago
  end
end
