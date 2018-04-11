class TagsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]

  def index
    @tags_index = true
    @tags = Tag.all.order("hotness_score DESC").first(100)
  end

  def edit
    @tag = Tag.find_by!(name: params[:tag])
    check_authorization
  end

  def update
    @tag = Tag.find_by!(id: params[:id])
    check_authorization
    if @tag.errors.messages.blank? && @tag.update(tag_params)
      flash[:success] = "Tag successfully updated! 👍 "
      redirect_to "/t/#{@tag.name}/edit"
    else
      flash[:error] = @tag.errors.full_messages
      render :edit
    end
  end

  private

  def check_authorization
    raise unless current_user.has_role?(:super_admin) || current_user.has_role?(:tag_moderator, @tag)
  end

  def convert_empty_string_to_nil
    # Andy: nil plays nicely with our hex colors, whereas empty string doesn't
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
