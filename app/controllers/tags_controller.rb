class TagsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index onboarding]
  before_action :authenticate_user!, only: %i[edit update]
  after_action :verify_authorized

  ATTRIBUTES_FOR_SERIALIZATION = %i[id name bg_color_hex text_color_hex short_summary badge_id].freeze
  INDEX_API_ATTRIBUTES = %i[name rules_html short_summary bg_color_hex badge_id].freeze

  TAGS_ALLOWED_PARAMS = %i[
    wiki_body_markdown
    rules_markdown
    short_summary
    pretty_name
    bg_color_hex
    text_color_hex
  ].freeze

  def index
    skip_authorization
    @tags_index = true
    @tags = params[:q].present? ? tags.search_by_name(params[:q]) : tags.order(hotness_score: :desc)
  end

  def bulk
    skip_authorization
    @tags = Tag.includes(:badge).select(ATTRIBUTES_FOR_SERIALIZATION)

    page = params[:page]
    per_page = (params[:per_page] || 10).to_i
    num = [per_page, 1000].min

    if params[:tag_ids].present?
      @tags = @tags.where(id: params[:tag_ids])
    elsif params[:tag_names].present?
      @tags = @tags.where(name: params[:tag_names])
    end

    @tags = @tags.order(taggings_count: :desc).page(page).per(num)
    render json: @tags, only: ATTRIBUTES_FOR_SERIALIZATION, include: [badge: { only: [:badge_image] }]
  end

  def edit
    @tag = Tag.find_by!(name: params[:tag])
    authorize @tag
  end

  def update
    @tag = Tag.find(params[:id])
    authorize @tag
    if @tag.errors.messages.blank? && @tag.update(tag_params)
      flash[:success] = I18n.t("tags_controller.tag_successfully_updated")
      redirect_to "#{URL.tag_path(@tag)}/edit"
    else
      flash.now[:error] = @tag.errors.full_messages
      render :edit
    end
  end

  def admin
    tag = Tag.find_by!(name: params[:tag])
    authorize tag
    redirect_to edit_admin_tag_path(tag.id)
  end

  def onboarding
    skip_authorization

    @tags = Tag.where(name: Settings::General.suggested_tags)
      .select(ATTRIBUTES_FOR_SERIALIZATION)

    set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
  end

  def suggest
    skip_authorization
    tags = Tag.supported.order(hotness_score: :desc).limit(100).select(INDEX_API_ATTRIBUTES)
    render json: tags, only: INDEX_API_ATTRIBUTES, include: [badge: { only: [:badge_image] }]
  end

  private

  def tags
    @tags ||= Tag.direct.order("hotness_score DESC").limit(100)
  end

  def convert_empty_string_to_nil
    # nil plays nicely with our hex colors, whereas empty string doesn't
    params[:tag][:text_color_hex] = nil if params[:tag][:text_color_hex] == ""
    params[:tag][:bg_color_hex] = nil if params[:tag][:bg_color_hex] == ""
  end

  def tag_params
    convert_empty_string_to_nil
    params.require(:tag).permit(TAGS_ALLOWED_PARAMS)
  end

  private_constant :ATTRIBUTES_FOR_SERIALIZATION
end
