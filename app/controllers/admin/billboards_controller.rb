module Admin
  class BillboardsController < Admin::ApplicationController
    layout "admin"

    INDEX_COLUMNS = %i[
      id name placement_area display_to type_of published approved success_rate
    ].freeze
    EVENT_COLUMNS = %i[id display_ad_id user_id category created_at].freeze
    RECENT_EVENTS_WINDOW = 30.days

    def index
      billboards = Billboard.select(*INDEX_COLUMNS).order(id: :desc)
      billboards = billboards.search_ads(params[:search]) if params[:search].present?
      @billboards = billboards.page(params[:page]).per(50).without_count
    end

    def show
      @billboard = Billboard.find(params[:id])
      @events = @billboard.billboard_events
        .select(*EVENT_COLUMNS)
        .where("created_at >= ?", RECENT_EVENTS_WINDOW.ago)
        .where.not(user_id: nil)
        .where.not(category: "impression")
        .order(created_at: :desc)
        .limit(25)
        .to_a
      ActiveRecord::Associations::Preloader.new(
        records: @events, associations: :user, scope: User.select(:id, :username),
      ).call
    end

    def new
      @billboard = Billboard.new
    end

    def edit
      @billboard = Billboard.find(params[:id])
    end

    def create
      @billboard = Billboard.new(billboard_params)
      @billboard.creator = current_user

      if @billboard.save
        flash[:success] = I18n.t("admin.billboards_controller.created")
        redirect_to edit_admin_billboard_path(@billboard.id)
      else
        flash[:danger] = @billboard.errors_as_sentence
        render :new
      end
    end

    def update
      @billboard = Billboard.find(params[:id])

      if @billboard.update(billboard_params)
        flash[:success] = I18n.t("admin.billboards_controller.updated")
        redirect_to edit_admin_billboard_path(params[:id])
      else
        flash[:danger] = @billboard.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @billboard = Billboard.find(params[:id])

      if @billboard.destroy
        render json: { message: I18n.t("admin.billboards_controller.deleted") }, status: :ok
      else
        render json: { error: I18n.t("admin.billboards_controller.wrong") }, status: :unprocessable_entity
      end
    end

    private

    def billboard_params
      params.permit(:organization_id, :body_markdown, :placement_area, :target_geolocations,
                    :published, :approved, :name, :display_to, :tag_list, :type_of, :color,
                    :exclude_article_ids, :audience_segment_id, :priority, :browser_context,
                    :exclude_role_names, :target_role_names, :include_subforem_ids,
                    :render_mode, :template, :custom_display_label, :requires_cookies, :expires_at,
                    :special_behavior, :minimized_body_markdown)
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end
  end
end
