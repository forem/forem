module Api
  module V1
    class PagesController < ApiController
      before_action :authenticate!, except: %i[show index]
      before_action :set_page, only: %i[show update destroy]

      def index
        @pages = if params[:organization_id].present?
                   Page.where(organization_id: params[:organization_id]).order(:position, :created_at, :id)
                 else
                   Page.all
                 end
        render json: @pages
      end

      def show
        render json: @page
      end

      def create
        if page_admin?
          @page = Page.new(permitted_params)
        else
          @organization = Organization.find_by(id: params[:organization_id])
          authorize_org_admin!(@organization)
          build_org_page
          return render_validation_error if @page.errors.any?
        end

        if @page.save
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def update
        if page_admin?
          return render json: @page, status: :ok if @page.update(permitted_params)

          return render_validation_error
        end

        @organization = @page.organization
        authorize_org_admin!(@organization)
        if params[:organization_id].present? && params[:organization_id].to_i != @organization.id
          raise Pundit::NotAuthorizedError
        end

        assign_org_page_updates
        return render_validation_error if @page.errors.any?

        if @page.save
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def destroy
        authorize_org_admin!(@page.organization) unless page_admin?

        if @page.destroy
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      private

      def set_page
        @page = Page.find(params[:id])
      end

      def page_admin?
        @user.administrative_access_to?(resource: Page)
      end

      def authorize_org_admin!(organization)
        return if organization.present? &&
          @user.org_admin?(organization) &&
          FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])

        raise Pundit::NotAuthorizedError
      end

      def build_org_page
        is_first_page = !@organization.pages.exists?
        @page = @organization.pages.build(org_admin_permitted_params)
        @page.template = "full_within_layout"

        if is_first_page
          @page.slug = "#{@organization.slug}/readme"
          @page.title = I18n.t("views.organizations.showcase") if @page.title.blank?
        else
          suffix = extract_org_slug_suffix
          if suffix.blank?
            @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
            return
          end
          @page.slug = "#{@organization.slug}/#{suffix}"
        end

        @page.position = if is_first_page || @page.slug.end_with?("/readme")
                           0
                         elsif params[:position].present?
                           [params[:position].to_i, 1].max
                         else
                           [(@organization.pages.maximum(:position) || 0) + 1, 1].max
                         end
        @page.description = @organization.summary.presence || @organization.name if @page.description.blank?
      end

      def assign_org_page_updates
        @page.assign_attributes(org_admin_permitted_params)
        @page.template = "full_within_layout"

        if @page.slug.end_with?("/readme")
          @page.slug = "#{@organization.slug}/readme"
          @page.position = 0
        else
          if params.key?(:slug) || params.key?(:slug_suffix)
            suffix = extract_org_slug_suffix
            if suffix.blank?
              @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
              return
            end
            @page.slug = "#{@organization.slug}/#{suffix}"
          end
          @page.position = [params[:position].to_i, 1].max if params[:position].present?
        end
      end

      def extract_org_slug_suffix
        raw_slug = (params[:slug_suffix].presence || params[:slug]).to_s.strip.sub(%r{\A/+}, "")
        org_prefix = "#{@organization.slug}/"
        if raw_slug.include?("/")
          return "" unless raw_slug.downcase.start_with?(org_prefix.downcase)

          raw_slug = raw_slug[org_prefix.length..]
          return "" if raw_slug.include?("/")
        end

        raw_slug.downcase.gsub(/[^a-z0-9\-]/, "-").squeeze("-").gsub(/\A-+|-+\z/, "")
      end

      def render_validation_error
        response.headers["X-Error-Text"] = @page.errors.full_messages.join(", ")
        render json: @page, status: :unprocessable_entity
      end

      def org_admin_permitted_params
        params.permit(:title, :description, :body_markdown)
      end

      def permitted_params
        if params[:social_image].present? && params[:social_image][:url].present?
          params[:remote_social_image_url] = params[:social_image][:url]
        end
        params.permit(*%i[title slug description is_top_level_path subforem_id
                          body_json body_markdown body_html body_css remote_social_image_url
                          template redirect_to_url organization_id position])
      end
    end
  end
end
