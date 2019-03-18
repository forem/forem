class Internal::TagsController < Internal::ApplicationController
  layout "internal"

  def index
    @tags = if params[:state] == "supported"
              Tag.where(supported: true).order("taggings_count DESC").page(params[:page]).per(50)
            elsif params[:state] == "unsupported"
              Tag.where(supported: false).order("taggings_count DESC").page(params[:page]).per(50)
            else
              Tag.order("taggings_count DESC").page(params[:page]).per(50)
            end
    @tags = @tags.where("tags.name ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def show
    @tag = Tag.find(params[:id])
  end

  def edit
    @tag = Tag.find(params[:id])
  end

  def update
    @tag = Tag.find(params[:id])
    add_moderator if params[:tag][:tag_moderator_id]
    remove_moderator if params[:tag][:remove_moderator_id]
    @tag.update!(tag_params)
    redirect_to "/internal/tags/#{params[:id]}"
  end

  private

  def remove_moderator
    User.find(params[:tag][:remove_moderator_id]).remove_role :tag_moderator, @tag
  end

  def add_moderator
    user_id = params[:tag][:tag_moderator_id]
    AssignTagModerator.add_tag_moderators([user_id], [@tag.id])
  end

  def tag_params
    params.require(:tag).permit(:supported,
                                :rules_markdown,
                                :short_summary,
                                :pretty_name,
                                :bg_color_hex,
                                :text_color_hex,
                                :tag_moderator_id,
                                :remove_moderator_id,
                                :alias_for)
  end
end
