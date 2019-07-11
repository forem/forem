class TagsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]
  before_action :authenticate_user!, only: %i[edit update]
  after_action :verify_authorized

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
    @tag = Tag.find_by!(id: params[:id])
    authorize @tag
    if @tag.errors.messages.blank? && @tag.update(tag_params)
      flash[:success] = "Tag successfully updated! 👍 "
      redirect_to "/t/#{@tag.name}/edit"
    else
      flash[:error] = @tag.errors.full_messages
      render :edit
    end
  end

  def admin
    tag = Tag.find_by!(name: params[:tag])
    authorize tag
    redirect_to "/admin/tags/#{tag.id}/edit"
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
end
