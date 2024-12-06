module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_resize'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - required - (String)
        #    The unique identifier of a cluster whose resize progress you are requesting.
        #    This parameter isn't case-sensitive. By default, resize operations for all
        #    clusters defined for an AWS account are returned.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeResize.html
        def describe_resize(options = {})
          cluster_identifier = options[:cluster_identifier]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeResize.new
          }

          params[:query]['Action']         = 'DescribeResize'
          params[:query]['ClusterIdentifier'] = cluster_identifier if cluster_identifier

          request(params)
        end
      end
    end
  end
end
