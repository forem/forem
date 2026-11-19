module Api
  module V1
    class PagesController < ApiController
      before_action :authenticate!, except: %i[show index]
      before_action :set_page, only: %i[show update destroy]

      def index
        return render_organization_embed_pages if params[:kind] == "embed"

        scope = Page.non_embed_html
        if can_view_draft_event_pages?
          prevent_caching
        else
          scope = visible_pages_scope(scope)
        end

        @pages = if params[:organization_id].present?
                   scope.where(organization_id: params[:organization_id])
                     .order(:position, :created_at, :id)
                 elsif params[:event_id].present?
                   scope.where(event_id: params[:event_id])
                     .order(:position, :created_at, :id)
                 else
                   scope
                 end
        render json: @pages
      end

      def show
        render json: @page
      end

      def create
        return create_organization_embed_page if params[:template] == Page::EMBED_HTML_TEMPLATE

        if page_admin?
          @page = Page.new(permitted_params)
        else
          @organization = find_organization_by_param
          authorize_org_admin!(@organization)
          build_org_page
          return render_validation_error if @page.errors.any?
        end

        if @page.save
          log_page_write("api_page_create")
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def update
        if page_admin? && !@page.embed_html?
          if @page.update(permitted_params)
            log_page_write("api_page_update")
            return render json: @page, status: :ok
          end

          return render_validation_error
        end

        @organization = @page.organization
        authorize_org_admin!(@organization) unless page_admin?
        if params[:organization_id].present? && !same_organization_id?(params[:organization_id], @organization.id)
          raise Pundit::NotAuthorizedError
        end

        if @page.embed_html?
          assign_org_embed_page_updates
        else
          assign_org_page_updates
        end
        return render_validation_error if @page.errors.any?

        if @page.save
          log_page_write("api_page_update")
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def destroy
        authorize_org_admin!(@page.organization, allow_page_management: false) unless page_admin?

        if @page.destroy
          log_page_write("api_page_destroy")
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def preview
        page_hash = extract_preview_page_hash
        org_id = params[:organization_id].presence || page_hash[:organization_id].presence
        @organization = Organization.find_by(id: org_id) if org_id.present?
        authorize_org_admin!(@organization) unless page_admin?

        body_markdown = params.key?(:body_markdown) ? params[:body_markdown] : page_hash[:body_markdown]
        body_html = params.key?(:body_html) ? params[:body_html] : page_hash[:body_html]

        processed_html = if body_markdown.blank? && body_html.present? && page_admin? && @organization.nil?
                           body_html
                         else
                           renderer = ContentRenderer.new(body_markdown.to_s, source: @organization, user: @user)
                           renderer.process(link_attributes: link_attributes_for_org(@organization)).processed_html
                         end

        render json: { processed_html: processed_html }, status: :ok
      rescue ContentRenderer::ContentParsingError => e
        error_unprocessable_entity(ErrorMessages::Clean.call(e.message))
      end

      private

      def render_organization_embed_pages
        prevent_caching
        @user = authenticated_user
        raise Pundit::NotAuthorizedError unless @user

        org_id = scalar_organization_id
        organization = Organization.find_by(id: org_id) if org_id
        if page_admin?
          raise ActionController::ParameterMissing, :organization_id unless org_id
          raise ActiveRecord::RecordNotFound unless organization
        else
          raise Pundit::NotAuthorizedError unless org_embed_page_reader?(organization)
        end

        render json: organization.ordered_embed_pages
      end

      def create_organization_embed_page
        @organization = find_organization_by_param
        if page_admin?
          raise ActionController::ParameterMissing, :organization_id unless @organization
        else
          authorize_org_admin!(@organization)
        end

        prevent_caching
        build_org_embed_page
        return render_validation_error if @page.errors.any?

        if @page.save
          log_page_write("api_page_create")
          render json: @page, status: :ok
        else
          render_validation_error
        end
      end

      def prevent_caching
        unset_cache_control_headers
        response.headers["Cache-Control"] = "private, no-store"
        response.headers["Surrogate-Control"] = "no-store"
      end

      def scalar_organization_id(raw_id = params[:organization_id])
        return unless raw_id.is_a?(Integer) || (raw_id.is_a?(String) && raw_id.match?(/\A\d+\z/))

        raw_id.to_i
      end

      def same_organization_id?(raw_id, organization_id)
        parsed = scalar_organization_id(raw_id)
        parsed.present? && parsed == organization_id
      end

      def find_organization_by_param(raw_id = params[:organization_id])
        org_id = scalar_organization_id(raw_id)
        Organization.find_by(id: org_id) if org_id
      end

      def log_page_write(action)
        via = if @via_page_management
                { "via" => "org_pages_resource_admin", "organization_id" => @page.organization_id }
              else
                {}
              end
        Audit::Logger.log(:admin_api, @user, { "action" => action, "page_id" => @page.id, **via })
      end

      def extract_preview_page_hash
        return params[:page] if params[:page].is_a?(ActionController::Parameters) || params[:page].is_a?(Hash)

        {}
      end

      def link_attributes_for_org(organization)
        return {} unless organization
        return {} if FeatureFlag.enabled?(:org_dofollow_links, FeatureFlag::Actor[organization])

        { rel: "nofollow ugc" }
      end

      def set_page
        @page = Page.find(params[:id])
        if @page.is_a?(Page) && @page.embed_html?
          @user ||= authenticated_user
          raise ActiveRecord::RecordNotFound unless org_embed_page_reader?(@page.organization)

          prevent_caching
          return
        end

        return unless action_name == "show" && @page.event_id.present?
        return if @page.event&.published?

        raise ActiveRecord::RecordNotFound unless can_view_draft_event_pages?

        prevent_caching
      end

      def visible_pages_scope(scope)
        scope.where(
          "pages.event_id IS NULL OR EXISTS (" \
          "SELECT 1 FROM events WHERE events.id = pages.event_id AND events.published = ?)",
          true,
        )
      end

      def can_view_draft_event_pages?
        user = authenticated_user
        return false unless user

        user.administrative_access_to?(resource: Page) || user.administrative_access_to?(resource: Event)
      end

      def org_embed_page_reader?(organization)
        return false unless @user && organization

        page_admin? || org_page_access(organization).present?
      end

      def page_admin?
        @user.administrative_access_to?(resource: Page)
      end

      def authorize_org_admin!(organization, allow_page_management: true)
        access = org_page_access(organization, allow_page_management: allow_page_management)
        raise Pundit::NotAuthorizedError unless access

        @via_page_management = access == :page_management
      end

      def org_page_access(organization, allow_page_management: true)
        return unless organization.present? && FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])
        return :org_admin if @user.org_admin?(organization)

        :page_management if allow_page_management && @user.single_resource_admin_for?(OrganizationPageManagement)
      end

      def build_org_page
        is_first_page = !@organization.ordered_pages.exists?
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
                           [(@organization.ordered_pages.maximum(:position) || 0) + 1, 1].max
                         end
        @page.description = @organization.summary.presence || @organization.name if @page.description.blank?
      end

      def build_org_embed_page
        @page = @organization.pages.build(embed_page_permitted_params)
        @page.template = Page::EMBED_HTML_TEMPLATE
        @page.position = 0
        @page.description = @organization.summary.presence || @organization.name if @page.description.blank?

        suffix = extract_org_slug_suffix("#{@organization.slug}/embed/")
        if suffix.blank?
          @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
          return
        end
        @page.slug = "#{@organization.slug}/embed/#{suffix}"
      end

      def assign_org_embed_page_updates
        @page.assign_attributes(embed_page_permitted_params)
        @page.template = params[:template] if params[:template].present?
        return unless params.key?(:slug) || params.key?(:slug_suffix)

        suffix = extract_org_slug_suffix("#{@organization.slug}/embed/")
        if suffix.blank?
          @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
          return
        end
        @page.slug = "#{@organization.slug}/embed/#{suffix}"
      end

      def assign_org_page_updates
        @page.assign_attributes(org_admin_permitted_params)
        @page.template = "full_within_layout"
        @page.template = Page::EMBED_HTML_TEMPLATE if params[:template] == Page::EMBED_HTML_TEMPLATE

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

      def extract_org_slug_suffix(org_prefix = "#{@organization.slug}/")
        raw_value = params[:slug_suffix].presence || params[:slug]
        return "" unless raw_value.is_a?(String) || raw_value.is_a?(Integer)

        raw_slug = raw_value.to_s.strip.sub(%r{\A/+}, "")
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
        params.permit(:title, :description, :body_markdown, :show_in_navigation)
      end

      def embed_page_permitted_params
        params.permit(:title, :description, :body_html)
      end

      def permitted_params
        if params[:social_image].present? && params[:social_image][:url].present?
          params[:remote_social_image_url] = params[:social_image][:url]
        end
        params.permit(*%i[title slug description is_top_level_path subforem_id
                          body_json body_markdown body_html body_css remote_social_image_url
                          template redirect_to_url organization_id event_id position show_in_navigation])
      end
    end
  end
end
