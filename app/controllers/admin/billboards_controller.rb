module Admin
  class BillboardsController < Admin::ApplicationController
    layout "admin"

    def index
      @billboards = Billboard.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @billboards = @billboards.search_ads(params[:search])
    end

    def show
      @billboard = Billboard.find(params[:id])
      @events = @billboard.billboard_events.order("created_at DESC").where.not(user_id: nil)
        .where.not(category: "impression").includes(:user).limit(25)
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
                    :render_mode, :template, :custom_display_label, :requires_cookies)
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end
  end
end
