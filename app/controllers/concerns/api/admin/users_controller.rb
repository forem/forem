module Api
  module Admin
    module UsersController
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

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
    end
  end
end
