require 'fog/aws/models/cdn/distribution'
require 'fog/aws/models/cdn/distributions_helper'

module Fog
  module AWS
    class CDN
      class Distributions < Fog::Collection
        include Fog::AWS::CDN::DistributionsHelper

        model Fog::AWS::CDN::Distribution

        attribute :marker,    :aliases => 'Marker'
        attribute :max_items, :aliases => 'MaxItems'
        attribute :is_truncated,    :aliases => 'IsTruncated'

        def get_distribution(dist_id)
          service.get_distribution(dist_id)
        end

        def list_distributions(options = {})
          service.get_distribution_list(options)
        end

        alias_method :each_distribution_this_page, :each
        alias_method :each, :each_distribution
      end
    end
  end
end
