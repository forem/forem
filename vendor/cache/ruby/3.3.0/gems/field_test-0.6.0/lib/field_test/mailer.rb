module FieldTest
  module Mailer
    extend ActiveSupport::Concern
    include Helpers

    included do
      helper_method :field_test
      helper_method :field_test_converted
      helper_method :field_test_experiments
    end

    def field_test_participant
      if @user
        @user
      elsif respond_to?(:params) && params
        params[:user]
      end
    end
  end
end
