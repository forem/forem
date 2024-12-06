# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class LoginLink < APIResource
    OBJECT_NAME = "login_link"

    def self.retrieve(_id, _opts = nil)
      raise NotImplementedError,
            "Login links do not have IDs and cannot be retrieved. They can " \
            "only be created using `Account.create_login_link('account_id', " \
            "create_params)`"
    end
  end
end
