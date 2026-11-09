module Admin
  class TagsController < Admin::ApplicationController
    layout "admin"

    ALLOWED_PARAMS = %i[
      id supported rules_markdown short_summary pretty_name bg_color_hex
      text_color_hex user_id alias_for badge_id requires_approval
      social_preview_template wiki_body_markdown submission_template
      suggested subforem_ids context_note_instructions moderation_instructions
    ].freeze

    before_action :set_default_options, only: %i[index]
    before_action :badges_for_options, only: %i[new edit]
    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @q = Tag.ransack(params[:q])
      @tags = @q.result.select(:id, :name, :alias_for, :taggings_count).page(params[:page]).per(50).load
      @moderated_tag_ids = moderated_tag_ids(@tags.map(&:id))
    end

    def new
      @tag = Tag.new
    end

    def edit
      @subforems = Subforem.select(:id, :domain).load
      @tag = Tag.find(params[:id])
      @existing_relationship_ids = @tag.subforem_relationships.pluck(:subforem_id).to_set
      @tag_moderators = @tag.tag_moderators.select(:id, :username).load
    end

    def create
      @tag = Tag.new(tag_params)
      @tag.name = params[:tag][:name].downcase

      if @tag.save
        flash[:success] = I18n.t("admin.tags_controller.created", tag_name: @tag.name)
        redirect_to edit_admin_tag_path(@tag)
      else
        badges_for_options
        flash[:danger] = @tag.errors_as_sentence
        render :new
      end
    end

    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params)
        ::Tags::AliasRetagWorker.perform_async(@tag.id) if tag_alias_updated?
        flash[:success] = I18n.t("admin.tags_controller.updated", tag_name: @tag.name)

        if tag_params[:subforem_ids].present? && tag_params[:subforem_ids].any?
          sync_subforem_relationships(tag_params[:subforem_ids].map(&:to_i).uniq)
        end
      else
        flash[:error] =
          I18n.t("admin.tags_controller.update_fail", errors: @tag.errors_as_sentence)
      end
      redirect_to edit_admin_tag_path(@tag.id)
    end

    private

    def set_default_options
      params[:q] = { supported_not_null: "true" } if params[:q].blank?
      params[:q][:s] = "taggings_count desc" if params[:q][:s].blank?
    end

    def badges_for_options
      @badges_for_options = Badge.pluck(:title, :id)
    end

    def moderated_tag_ids(tag_ids)
      return Set.new if tag_ids.empty?

      resource_ids = Role.where(name: "tag_moderator", resource_type: "Tag", resource_id: [nil, *tag_ids])
        .or(Role.where(name: "tag_moderator", resource_type: nil, resource_id: nil))
        .where("EXISTS (SELECT 1 FROM users_roles WHERE users_roles.role_id = roles.id)")
        .pluck(:resource_id)
      return tag_ids.to_set if resource_ids.include?(nil)

      resource_ids.to_set
    end

    def sync_subforem_relationships(desired_subforem_ids)
      existing_subforem_ids = @tag.subforem_relationships.pluck(:subforem_id)
      (desired_subforem_ids - existing_subforem_ids).each do |subforem_id|
        @tag.subforem_relationships.create(subforem_id: subforem_id)
      end
      @tag.subforem_relationships.where.not(subforem_id: desired_subforem_ids).destroy_all
    end

    def tag_params
      params.require(:tag).permit(ALLOWED_PARAMS, subforem_ids: [])
    end

    def tag_alias_updated?
      tag_params[:alias_for].present?
    end
  end
end
