module Admin
  class TagsController < Admin::ApplicationController
    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params) && @tag.errors.messages.blank? && handle_moderators
        flash[:notice] = "Tag successfully updated"
        redirect_to "/admin/tags/#{@tag.id}"
      else
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, @tag) }
      end
    end

    private

    def convert_empty_string_to_nil
      # nil plays nicely with our hex colors, whereas empty string doesn't
      params[:tag][:text_color_hex] = nil if params[:tag][:text_color_hex] == ""
      params[:tag][:bg_color_hex] = nil if params[:tag][:bg_color_hex] == ""
    end

    def tag_params
      accessible = %i[
        name
        supported
        alias_for
        wiki_body_markdown
        rules_markdown
        short_summary
        requires_approval
        submission_template
        submission_rules_headsup
        pretty_name
        bg_color_hex
        text_color_hex
        keywords_for_search
      ]
      convert_empty_string_to_nil
      params.require(:tag).permit(accessible)
    end

    def handle_moderators
      user_ids = params[:tag][:tag_moderator_ids].split(",")
      UserRoleService.new(nil, current_user.id).update_tag_moderators(user_ids.sort, @tag)
    end
  end
end
