module Admin
  class TagsController < Admin::ApplicationController
    layout "admin"

    before_action :badges_for_options, only: %i[new create edit update]
    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @tags = case params[:state]
              when "supported"
                Tag.where(supported: true).order(taggings_count: :desc).page(params[:page]).per(50)
              when "unsupported"
                Tag.where(supported: false).order(taggings_count: :desc).page(params[:page]).per(50)
              else
                Tag.order(taggings_count: :desc).page(params[:page]).per(50)
              end
      @tags = @tags.where("tags.name ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = Tag.new(tag_params)
      @tag.name = params[:tag][:name].downcase

      if @tag.save
        flash[:success] = "Tag has been created!"
        redirect_to edit_admin_tag_path(@tag)
      else
        flash[:danger] = @tag.errors_as_sentence
        render :new
      end
    end

    def edit
      @tag = Tag.find(params[:id])
      @tag_moderators = User.with_role(:tag_moderator, @tag).select(:id, :username)
    end

    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params)
        flash[:success] = "#{@tag.name} tag successfully updated!"
      else
        flash[:error] = "The tag update failed: #{@tag.errors_as_sentence}"
      end
      redirect_to edit_admin_tag_path(@tag.id)
    end

    private

    def badges_for_options
      @badges_for_options = Badge.pluck(:title, :id)
    end

    def tag_params
      allowed_params = %i[
        id supported rules_markdown short_summary pretty_name bg_color_hex
        text_color_hex user_id alias_for badge_id requires_approval
        category social_preview_template wiki_body_markdown submission_template
      ]
      params.require(:tag).permit(allowed_params)
    end
  end
end
