module Admin
  class OrgFeaturesController < Admin::ApplicationController
    layout "admin"

    FEATURES = {
      org_readme: {
        name: "Readme Page",
        description: "When enabled, organizations can build and display a custom readme page on their profile."
      },
      org_lead_forms: {
        name: "Lead Forms",
        description: "When enabled, organizations can create and manage lead capture forms to embed in their articles."
      },
      org_dofollow_links: {
        name: "Dofollow Links",
        description: "When enabled, links in this organization's readme page are dofollow (pass SEO authority). When disabled, all links are nofollow."
      }
    }.freeze

    def index
      @features = FEATURES.map do |key, config|
        feature = Flipper.feature(key)
        globally_enabled = feature.state == :on

        # Get per-org enablements from Flipper gates.
        # FeatureFlag::Actor wraps objects and returns their `id` as flipper_id,
        # so actor values are stored as plain integer strings (e.g. "42").
        # Since these are org-specific features, all actors are organizations.
        org_ids = []
        unless globally_enabled
          actor_ids = feature.actors_value
          org_ids = actor_ids.map { |actor_id| actor_id.to_i }
        end
        orgs = org_ids.any? ? Organization.where(id: org_ids).order(:name) : []

        {
          key: key,
          name: config[:name],
          description: config[:description],
          globally_enabled: globally_enabled,
          enabled_orgs: orgs
        }
      end

      @cta_text = ::Settings::General.org_features_cta_text
      @cta_url = ::Settings::General.org_features_cta_url
    end

    def toggle_global
      feature = params[:feature]&.to_sym
      unless FEATURES.key?(feature)
        flash[:error] = I18n.t("admin.org_features_controller.invalid_feature")
        return redirect_to admin_org_features_path
      end

      if params[:enabled] == "true"
        FeatureFlag.enable(feature)
      else
        FeatureFlag.disable(feature)
      end

      status = params[:enabled] == "true" ? "enabled" : "disabled"
      flash[:notice] = I18n.t("admin.org_features_controller.global_#{status}", feature: FEATURES[feature][:name])
      redirect_to admin_org_features_path
    end

    def update_cta
      ::Settings::General.org_features_cta_text = params[:cta_text]
      ::Settings::General.org_features_cta_url = params[:cta_url]
      flash[:notice] = I18n.t("admin.org_features_controller.cta_updated")
      redirect_to admin_org_features_path
    end

    protected

    def authorization_resource
      Organization
    end
  end
end
