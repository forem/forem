# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  module API
    require_relative "api/approle"
    require_relative "api/auth_token"
    require_relative "api/auth_tls"
    require_relative "api/auth"
    require_relative "api/help"
    require_relative "api/kv"
    require_relative "api/logical"
    require_relative "api/secret"
    require_relative "api/sys"
    require_relative "api/transform"
  end
end
