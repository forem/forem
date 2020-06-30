module UserSubscriptions
  class Create
    attr_accessor :user, :source_type, :source_id, :subscriber_email

    def self.call(*args)
      new(*args).call
    end

    def initialize(user, user_subscription_params)
      @user = user
      @source_type = user_subscription_params[:source_type]
      @source_id = user_subscription_params[:source_id]

      # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
      # @subscriber_email = user_subscription_params[:subscriber_email]
    end

    def call
      response = new_response

      response.error = "Invalid source_type." unless UserSubscription::ALLOWED_TYPES.include?(source_type)
      return response if response.error

      source = source_type.constantize.find_by(id: source_id)
      response.error = "Source not found." unless source
      return response if response.error

      # This checks if the email address the user saw/consented to share is the
      # same as their current email address. A mismatch occurs if a user updates
      # their email address in a new/separate tab and then tries to subscribe on
      # the old/stale tab without refreshing. In that case, the user would have
      # consented to share their old email address instead of the current one.
      # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
      # response.error = "Subscriber email mismatch." unless user.email == subscriber_email
      # return response if response.error

      user_subscription = source.build_user_subscription(user)
      if user_subscription.save
        response.success = true
        response.data = user_subscription
      else
        response.error = user_subscription.errors.full_messages.to_sentence
      end

      response
    end

    private

    def new_response
      response_struct = Struct.new(:success, :data, :error, keyword_init: true)
      response_struct.new(success: false, data: nil, error: nil)
    end
  end
end
