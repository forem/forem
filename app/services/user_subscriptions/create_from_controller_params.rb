module UserSubscriptions
  # When creating a UserSubscription from a controller/user interation on the
  # frontend, we need to do some extra validations and logic.
  class CreateFromControllerParams
    attr_reader :user, :source_type, :source_id, :subscriber_email, :response

    Response = Struct.new(:success, :data, :error, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(user, user_subscription_params)
      @user = user
      @source_type = user_subscription_params[:source_type]
      @source_id = user_subscription_params[:source_id]
      @response = Response.new(success: false)

      # TODO: [@forem/delightful]: uncomment this once email confirmation is re-enabled
      # @subscriber_email = user_subscription_params[:subscriber_email]
    end

    def call
      return response if invalid_source_type?

      source = source_type.constantize.find_by(id: source_id)
      return response if invalid_source?(source)

      # TODO: [@forem/delightful]: uncomment this once email confirmation is re-enabled
      # return response if subscriber_email_mismatch?

      user_subscription = source.build_user_subscription(user)
      if user_subscription.save
        response.success = true
        response.data = user_subscription
      else
        response.error = user_subscription.errors_as_sentence
      end

      response
    end

    private

    def invalid_source_type?
      return false if UserSubscription::ALLOWED_TYPES.include?(source_type)

      response.error = "Invalid source_type."
      true
    end

    def invalid_source?(source)
      return false if source

      response.error = "Source not found."
      true
    end

    def subscriber_email_mismatch?
      # This checks if the email address the user saw/consented to share is the
      # same as their current email address. A mismatch occurs if a user updates
      # their email address in a new/separate tab and then tries to subscribe on
      # the old/stale tab without refreshing. In that case, the user would have
      # consented to share their old email address instead of the current one.
      return false if user.email == subscriber_email

      response.error = "Subscriber email mismatch."
      true
    end
  end
end
