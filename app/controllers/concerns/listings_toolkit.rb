# Helpers for controllers interacting with Listing
module ListingsToolkit
  extend ActiveSupport::Concern

  MANDATORY_FIELDS_FOR_UPDATE = %i[body_markdown title tag_list].freeze

  def create
    @listing = Listing.new(listing_params)
    organization_id = @listing.organization_id

    # this will 401 for now if they don't belong in the org
    authorize @listing, :authorized_organization_poster? if organization_id.present?

    @listing.user_id = current_user.id

    if listing_params[:action] == "draft"
      create_draft
      return
    end

    if @listing.invalid? || rate_limit?
      @credits = current_user.credits.unspent
      process_unsuccessful_creation
      return
    end

    purchase_successful = @listing.purchase(current_user) do |purchaser|
      create_listing(purchaser, @listing.cost)
    end
    process_no_credit_left unless purchase_successful
  end

  ALLOWED_PARAMS = %i[
    title body_markdown listing_category_id tag_list
    expires_at location organization_id action
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
    create_result = Listings::Create.call(@listing, purchaser: purchaser, cost: cost)

    if create_result.success?
      rate_limiter.track_limit_by_action(:listing_creation)
      @listing.clear_cache
      process_successful_creation
    else
      @credits = current_user.credits.unspent
      @listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      process_unsuccessful_creation
    end
  end

  def update
    # NOTE: this should probably be split in three different actions: bump, unpublish, publish
    if listing_params[:action] == "bump"
      bump_result = Listings::Bump.call(@listing, user: current_user)
      return process_no_credit_left unless bump_result
    end

    if listing_params[:action] == "unpublish"
      @listing.unpublish
      process_after_unpublish
      return
    elsif listing_params[:action] == "publish"
      unless @listing.bumped_at?
        first_publish(@listing.cost)
        return
      end

      @listing.publish
    elsif listing_updatable?
      saved = @listing.update(listing_params.compact)
      return process_unsuccessful_update unless saved
    end

    @listing.clear_cache
    process_after_update
  end

  private

  def set_and_authorize_listing
    @listing = Listing.find(params[:id])
    authorize @listing
  end

  def rate_limit?
    begin
      rate_limit!(:listing_creation)
    rescue ::RateLimitChecker::LimitReached => e
      @listing.errors.add(:listing_creation, e.message)
      return true
    end
    false
  end

  def first_publish(cost)
    author = @listing.author
    available_user_credits = author.is_a?(Organization) ? current_user.credits.unspent.size : 0

    if author.enough_credits?(cost)
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
    @listing.bumped_at&.after?(24.hours.ago)
  end
end
