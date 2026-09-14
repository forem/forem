module Admin
  class OrganizationsController < Admin::ApplicationController
    layout "admin"
    PER_PAGE_MAX = 50
    ORG_FEATURES = %w[org_readme org_lead_forms org_dofollow_links org_verification].freeze

    CREDIT_ACTIONS = {
      add: :add_to,
      remove: :remove_from
    }.with_indifferent_access.freeze

    def index
      @q = Organization.ransack(params[:q])
      @q.sorts = 'created_at desc' if @q.sorts.empty?
      @organizations = @q.result.page(params[:page]).per(PER_PAGE_MAX)
    end

    def show
      @organization = Organization.find(params[:id])
    end

    def update_org_credits
      org = Organization.find(params[:id])
      amount = params[:credits].to_i
      update_action = CREDIT_ACTIONS.fetch(params[:credit_action])

      Credit.public_send(update_action, org, amount)
      add_note(org)
      Audit::Logger.log(:moderator, current_user, {
                          "action" => params[:action],
                          "controller" => params[:controller],
                          "target_organization_id" => org.id,
                          "credit_action" => params[:credit_action],
                          "credits" => amount
                        })

      flash[:notice] = I18n.t("admin.organizations_controller.credit_updated")
      redirect_to admin_organization_path(org)
    end

    def update_fully_trusted
      org = Organization.find(params[:id])
      old_status = org.fully_trusted?
      org.update!(fully_trusted: params[:fully_trusted] == "true")

      if old_status != org.fully_trusted?
        Note.create(
          author_id: current_user.id,
          noteable_id: org.id,
          noteable_type: "Organization",
          reason: "misc_note",
          content: "Fully trusted status #{org.fully_trusted? ? 'enabled' : 'disabled'}",
        )
        Audit::Logger.log(:moderator, current_user, {
                            "action" => params[:action],
                            "controller" => params[:controller],
                            "target_organization_id" => org.id,
                            "fully_trusted" => org.fully_trusted?
                          })
      end

      status = org.fully_trusted? ? "enabled" : "disabled"
      flash[:notice] = I18n.t("admin.organizations_controller.fully_trusted_#{status}")
      redirect_to admin_organization_path(org)
    end

    def update_baseline_score
      org = Organization.find(params[:id])
      old_score = org.baseline_score
      new_score = params[:baseline_score].to_i

      org.update!(baseline_score: new_score)

      if old_score != org.baseline_score
        Note.create(
          author_id: current_user.id,
          noteable_id: org.id,
          noteable_type: "Organization",
          reason: "misc_note",
          content: "Baseline score changed from #{old_score} to #{new_score}",
        )
        Audit::Logger.log(:moderator, current_user, {
                            "action" => params[:action],
                            "controller" => params[:controller],
                            "target_organization_id" => org.id,
                            "old_baseline_score" => old_score,
                            "new_baseline_score" => org.baseline_score
                          })
      end

      flash[:notice] = I18n.t("admin.organizations_controller.baseline_score_updated")
      redirect_to admin_organization_path(org)
    end

    def update_verified
      org = Organization.find(params[:id])
      new_verified = params[:verified] == "true"
      old_verified = org.verified?

      if new_verified
        org.update_columns(verified: true, verified_at: Time.current,
                           verification_status: Organization::VERIFICATION_STATUS_ADMIN,
                           baseline_score: ::Settings::UserExperience.index_minimum_score.to_i)
      else
        org.update_columns(verified: false, verified_at: nil, verification_url: nil, baseline_score: 0)
      end

      if old_verified != org.verified?
        Note.create(
          author_id: current_user.id,
          noteable_id: org.id,
          noteable_type: "Organization",
          reason: "misc_note",
          content: "Verified status #{org.verified? ? 'enabled (manually)' : 'disabled'}",
        )
        Audit::Logger.log(:moderator, current_user, {
                            "action" => params[:action],
                            "controller" => params[:controller],
                            "target_organization_id" => org.id,
                            "verified" => org.verified?
                          })
      end

      status = org.verified? ? "enabled" : "disabled"
      flash[:notice] = I18n.t("admin.organizations_controller.verified_#{status}")
      redirect_to admin_organization_path(org)
    end

    def update_org_feature
      org = Organization.find(params[:id])
      feature = params[:feature]

      unless ORG_FEATURES.include?(feature)
        flash[:error] = I18n.t("admin.organizations_controller.org_feature_invalid")
        return redirect_to admin_organization_path(org)
      end

      actor = FeatureFlag::Actor[org]
      if params[:enabled] == "true"
        FeatureFlag.enable(feature.to_sym, actor)
      else
        FeatureFlag.disable(feature.to_sym, actor)
      end

      status = params[:enabled] == "true" ? "enabled" : "disabled"
      Note.create(
        author_id: current_user.id,
        noteable_id: org.id,
        noteable_type: "Organization",
        reason: "misc_note",
        content: "Org feature '#{feature}' #{status}",
      )
      Audit::Logger.log(:moderator, current_user, {
                          "action" => params[:action],
                          "controller" => params[:controller],
                          "target_organization_id" => org.id,
                          "feature" => feature,
                          "enabled" => params[:enabled] == "true"
                        })

      # Reprocess org pages when dofollow flag changes so link attributes are updated
      if feature == "org_dofollow_links"
        org.pages.find_each(&:save!)
      end

      flash[:notice] = I18n.t("admin.organizations_controller.org_feature_#{status}", feature: feature.humanize)
      redirect_to admin_organization_path(org)
    end

    def bulk_add_users
      org = Organization.find(params[:id])
      result = Organizations::BulkAddUsers.call(
        organization: org,
        usernames: params[:usernames],
        role: params[:role],
      )

      log_bulk_add_audit_and_notes(org, result)
      set_bulk_add_flash_message(result)

      redirect_to admin_organization_path(org)
    end

    def destroy
      organization = Organization.find_by(id: params[:id])
      Organizations::DeleteWorker.perform_async(organization.id, current_user.id, false)

      flash[:settings_notice] =
        I18n.t("admin.organizations_controller.deletion_scheduled", organization_name: organization.name)
      redirect_to admin_organization_url(params[:id])
    rescue StandardError => e
      flash[:error] = I18n.t("admin.organizations_controller.error", organization_name: organization.name, error: e)
      redirect_to user_settings_path(:organization, id: organization.id)
    end

    private

    def add_note(org)
      Note.create(
        author_id: current_user.id,
        noteable_id: org.id,
        noteable_type: "Organization",
        reason: "misc_note",
        content: params[:note],
      )
    end

    def log_bulk_add_audit_and_notes(org, result)
      if result.added_users.any?
        Note.create(
          author_id: current_user.id,
          noteable_id: org.id,
          noteable_type: "Organization",
          reason: "misc_note",
          content: "Bulk added #{result.added_users.size} user(s) as #{result.role}: #{result.added_users.join(', ')}",
        )
      end

      Audit::Logger.log(:moderator, current_user, {
                          "action" => params[:action],
                          "controller" => params[:controller],
                          "target_organization_id" => org.id,
                          "role" => result.role,
                          "added_users" => result.added_users,
                          "already_members" => result.already_members,
                          "not_found" => result.not_found,
                          "failed_users" => result.failed_users
                        })
    end

    def set_bulk_add_flash_message(result)
      if result.empty_input?
        flash[:error] = I18n.t("admin.organizations_controller.bulk_add_users.empty_input")
        return
      end

      messages = bulk_add_result_messages(result)
      if result.added_users.any?
        flash[:notice] = messages.join(" ")
      else
        flash[:error] = messages.join(" ")
      end
    end

    def bulk_add_result_messages(result)
      messages = []
      if result.added_users.any?
        messages << I18n.t("admin.organizations_controller.bulk_add_users.added",
                           count: result.added_users.size, usernames: result.added_users.join(", "))
      end
      if result.already_members.any?
        messages << I18n.t("admin.organizations_controller.bulk_add_users.already_members",
                           count: result.already_members.size, usernames: result.already_members.join(", "))
      end
      if result.not_found.any?
        messages << I18n.t("admin.organizations_controller.bulk_add_users.not_found",
                           count: result.not_found.size, usernames: result.not_found.join(", "))
      end
      if result.failed_users.any?
        messages << I18n.t("admin.organizations_controller.bulk_add_users.failed",
                           count: result.failed_users.size, errors: result.failed_users.join(", "))
      end
      messages
    end
  end
end
