module Users
  class AccessTokenController < ApplicationController
    # Structs that help mimic auth_payload compatible with Authentication::Authenticator
    Info = Struct.new(:name, :email, :image)
    Extra = Struct.new(:raw_info)
    RawInfo = Struct.new(:id, :created_at, :auth_time)
    Payload = Struct.new(:provider, :info, :extra)

    def facebook
      # Create a payload compatible with the Authentication::Authenticator service
      auth_payload = Payload.new(
        "facebook",
        Info.new(
          params[:name],
          params[:email],
          params[:image],
        ),
        Extra.new(RawInfo.new(params[:uid])),
      )

      # Reuse the service used in OmniauthCallbacksController that handles
      # social providers + Identity creation
      @user = Authentication::Authenticator.call(
        auth_payload,
        current_user: current_user,
        cta_variant: params[:cta_variant],
        access_token: params[:access_token],
      )

      if user_persisted_and_valid?
        remember_me(@user)
        sign_in_and_redirect(@user, event: :authentication)
      elsif user_persisted_but_username_taken?
        redirect_to "/settings?state=previous-registration"
      else
        user_errors = @user.errors.full_messages

        Honeybadger.context({
                              username: @user.username,
                              user_id: @user.id,
                              auth_data: auth_payload,
                              auth_error: "Access Token authentication error",
                              user_errors: user_errors
                            })
        Honeybadger.notify("Access Token authentication error")

        flash[:alert] = user_errors
        redirect_to new_user_registration_url
      end
    rescue ::Authentication::Errors::PreviouslySuspended => e
      flash[:global_notice] = e.message
      redirect_to root_path
    rescue StandardError => e
      Honeybadger.notify(e)

      flash[:alert] = "Log in error: #{e}"
      redirect_to new_user_registration_url
    end

    private

    def user_persisted_and_valid?
      @user.persisted? && @user.valid?
    end

    def user_persisted_but_username_taken?
      @user.persisted? && @user.errors_as_sentence.include?("username has already been taken")
    end
  end
end
