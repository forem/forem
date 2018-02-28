class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable
  def self.provides_callback_for(provider)
    # raise env["omniauth.auth"].to_yaml
    class_eval %Q{
      def #{provider}
        cta_variant = request.env["omniauth.params"]['state']
        @user = AuthorizationService.new(request.env["omniauth.auth"], current_user, cta_variant).get_user
        if @user.persisted?
          remember_me(@user)
          sign_in_and_redirect @user, event: :authentication
          set_flash_message(:notice, :success, kind: "#{provider}".capitalize) if is_navigational_format?
        else
          session["devise.#{provider}_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    }
  end

  [:twitter, :github].each do |provider|
    provides_callback_for provider
  end

end
