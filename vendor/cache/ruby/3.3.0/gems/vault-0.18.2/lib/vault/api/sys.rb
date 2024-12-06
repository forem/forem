# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {Sys} methods.
    # @return [Sys]
    def sys
      @sys ||= Sys.new(self)
    end
  end

  class Sys < Request; end
end

require_relative "sys/audit"
require_relative "sys/auth"
require_relative "sys/health"
require_relative "sys/init"
require_relative "sys/leader"
require_relative "sys/lease"
require_relative "sys/mount"
require_relative "sys/namespace"
require_relative "sys/policy"
require_relative "sys/quota"
require_relative "sys/seal"
