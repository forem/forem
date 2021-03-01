module Admin
  class SecretsController < Admin::ApplicationController
    layout "admin"

    before_action :validate_settable_secret, only: [:update]
    after_action only: [:update] do
      Audit::Logger.log(:internal, current_user, params.dup)
    end

    def index
      @vault_enabled = AppSecrets.vault_enabled?
      @secrets = AppSecrets::SETTABLE_SECRETS.map do |key|
        secret_value = AppSecrets[key]
        secret_value = secret_value.present? ? "#{secret_value.first(8)}******" : "Not In Vault"
        [key, secret_value]
      end
    end

    def update
      AppSecrets[params[:key_name]] = params[:key_value]

      flash[:success] = "Secret #{params[:key_name]} was successfully updated in Vault."
      redirect_to admin_secrets_path
    end

    private

    def validate_settable_secret
      update_param = params.permit(*AppSecrets::SETTABLE_SECRETS)
      params[:key_name], params[:key_value] = update_param.to_h.to_a.first

      bad_request unless update_param.present? && params[:key_name].is_a?(String) && params[:key_value].is_a?(String)
    end
  end
end
