# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class Quota < Response
    # @!attribute [r] name
    #   Name of the quota rule.
    #   @return [String]
    field :name

    # @!attribute [r] path
    #   Namespace/Path combination the quota applies to.
    #   @return [String]
    field :path

    # @!attribute [r] type
    #   Type of the quota rule, must be one of "lease-count" or "rate-limit"
    #   @return [String]
    field :type
  end

  class RateLimitQuota < Quota
    # @!attribute [r] rate
    #   The rate at which allowed requests are refilled per second by the quota
    #   rule.
    #   @return [Float]
    field :rate

    # @!attribute [r] burst
    #   The maximum number of requests at any given second allowed by the quota
    #   rule.
    #   @return [Int]
    field :burst
  end

  class LeaseCountQuota < Quota
    # @!attribute [r] counter
    #   Number of currently active leases for the quota.
    #   @return [Int]
    field :counter

    # @!attribute [r] max_leases
    #   The maximum number of allowed leases for this quota.
    #   @return [Int]
    field :max_leases
  end

  class Sys
    def quotas(type)
      path = generate_path(type)
      json = client.list(path)
      if data = json.dig(:data, :key_info)
        data.map do |item|
          type_class(type).decode(item)
        end
      else
        json
      end
    end

    def create_quota(type, name, opts={})
      path = generate_path(type, name)
      client.post(path, JSON.fast_generate(opts))
      return true
    end

    def delete_quota(type, name)
      path = generate_path(type, name)
      client.delete(path)
      return true
    end

    def get_quota(type, name)
      path = generate_path(type, name)
      response = client.get(path)
      if data = response[:data]
        type_class(type).decode(data)
      end
    end

    def get_quota_config
      client.get("v1/sys/quotas/config")
    end
    
    def update_quota_config(opts={})
      client.post("v1/sys/quotas/config", JSON.fast_generate(opts))
      return true
    end

    private

    def generate_path(type, name=nil)
      verify_type(type)
      path = ["v1", "sys", "quotas", type, name].compact
      path.join("/")
    end

    def verify_type(type)
      return if ["rate-limit", "lease-count"].include?(type)
      raise ArgumentError, "type must be one of \"rate-limit\" or \"lease-count\""
    end

    def type_class(type)
      case type
      when "lease-count" then LeaseCountQuota
      when "rate-limit" then RateLimitQuota
      end
    end
  end
end
