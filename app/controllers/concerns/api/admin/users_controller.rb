module Api
  module Admin
    module UsersController
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100
      USER_UPDATE_FIELDS = %i[name username].freeze
      PROFILE_UPDATE_FIELDS = %i[summary location website_url].freeze

      def index
        users = filtered_users
        page = positive_integer(params[:page], default: 1)
        per_page = [positive_integer(params[:per_page], default: DEFAULT_PER_PAGE), MAX_PER_PAGE].min

        total = users.count
        @users = users.includes(:identities, :profile, :roles)
                      .order(created_at: :desc)
                      .offset((page - 1) * per_page)
                      .limit(per_page)
        @page = page
        @per_page = per_page
        @total = total
      end

      def show
        @user_record = User.find(params[:id])
      end

      def update
        @user_record = User.find(params[:id])
        before_user = @user_record.slice(*USER_UPDATE_FIELDS)
        before_profile = (@user_record.profile || @user_record.build_profile).slice(*PROFILE_UPDATE_FIELDS)

        user_attrs    = params.permit(*USER_UPDATE_FIELDS).to_h.symbolize_keys
        profile_attrs = params.permit(*PROFILE_UPDATE_FIELDS).to_h.symbolize_keys

        result = Users::Update.call(@user_record, user: user_attrs, profile: profile_attrs)
        unless result.success?
          apply_profile_errors!(@user_record)
          raise ActiveRecord::RecordInvalid, @user_record
        end

        after_user = @user_record.reload.slice(*USER_UPDATE_FIELDS)
        after_profile = (@user_record.profile || Profile.new).slice(*PROFILE_UPDATE_FIELDS)
        changed = diff_changed(before_user.merge(before_profile), after_user.merge(after_profile))

        audit!(slug: "update_user", data: { "target_user_id" => @user_record.id, "changed" => changed })
      end

      def update_email
        @user_record = User.find(params[:id])
        new_email = params.require(:email)
        old_email = @user_record.email

        if new_email !~ URI::MailTo::EMAIL_REGEXP
          raise Api::Admin::ApiError.new(:validation_failed, "Email is invalid", status: 422)
        end
        if User.where.not(id: @user_record.id).exists?(email: new_email)
          raise Api::Admin::ApiError.new(:email_taken, "Email already in use", status: 409)
        end

        @user_record.update_columns(email: new_email)
        audit!(slug: "update_user_email",
               data: { "target_user_id" => @user_record.id, "old_email" => old_email, "new_email" => new_email })
        render json: { id: @user_record.id, email: new_email }
      end

      def create
        # NOTE: We can add an inviting user here, e.g. User.invite!(current_user, user_params).
        options = {
          custom_invite_subject: params[:custom_invite_subject],
          custom_invite_message: params[:custom_invite_message],
          custom_invite_footnote: params[:custom_invite_footnote]
        }

        User.invite!(invite_params.merge(registered: false), nil, options)

        head :ok
      end

      private

      def filtered_users
        scope = User.all
        scope = scope.where(email: params[:email]) if params[:email].present?
        scope = scope.where(username: params[:username]) if params[:username].present?
        if params[:identity_provider].present? && params[:identity_uid].present?
          scope = scope.joins(:identities)
            .where(identities: {
                     provider: params[:identity_provider],
                     uid: params[:identity_uid]
                   })
        end
        scope
      end

      def positive_integer(value, default:)
        n = value.to_i
        n.positive? ? n : default
      end

      # Given that we expect creators to use tools (e.g. their existing SSO,
      # Zapier, etc) to post to this endpoint I wanted to keep the param
      # structure as simple and flat as possible, hence slightly more manual
      # param handling.
      #
      # NOTE: username is required for the validations on User to succeed.
      def invite_params
        {
          email: params.require(:email),
          name: params[:name],
          username: params[:email]
        }.compact_blank
      end

      def apply_profile_errors!(user_record)
        profile_errors = user_record.profile&.errors&.messages || {}
        profile_errors.each { |attr, msgs| msgs.each { |m| user_record.errors.add(attr, m) } }
      end

      def diff_changed(before, after)
        before.each_with_object({}) do |(key, before_val), memo|
          after_val = after[key]
          memo[key.to_s] = [before_val, after_val] if before_val != after_val
        end
      end
    end
  end
end
