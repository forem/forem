class TagsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index onboarding]
  before_action :authenticate_user!, only: %i[edit update]
  after_action :verify_authorized

  ATTRIBUTES_FOR_SERIALIZATION = %i[id name bg_color_hex text_color_hex].freeze

  def index
    skip_authorization
    @tags_index = true
    @tags = Tag.includes(:sponsorship).order(hotness_score: :desc).limit(100)
  end

  def edit
    @tag = Tag.find_by!(name: params[:tag])
    authorize @tag
  end

  def update
    @tag = Tag.find(params[:id])
    authorize @tag
    if @tag.errors.messages.blank? && @tag.update(tag_params)
      flash[:success] = "Tag successfully updated! 👍 "
      redirect_to "/t/#{URI.parse(@tag.name).path}/edit"
    else
      flash[:error] = @tag.errors.full_messages
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

    @tags = Tag.where(name: SiteConfig.suggested_tags)
      .select(ATTRIBUTES_FOR_SERIALIZATION)

    set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
  end

  private

  def convert_empty_string_to_nil
    # nil plays nicely with our hex colors, whereas empty string doesn't
    params[:tag][:text_color_hex] = nil if params[:tag][:text_color_hex] == ""
    params[:tag][:bg_color_hex] = nil if params[:tag][:bg_color_hex] == ""
  end

  def tag_params
    accessible = %i[
      wiki_body_markdown
      rules_markdown
      short_summary
      pretty_name
      bg_color_hex
      text_color_hex
    ]
    convert_empty_string_to_nil
    params.require(:tag).permit(accessible)
  end

  private_constant :ATTRIBUTES_FOR_SERIALIZATION
end
