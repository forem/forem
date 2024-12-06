module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/describe_services'

        # Describes the specified services running in your cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeServices.html
        # ==== Parameters
        # * cluster <~String> - name of the cluster that hosts the service you want to describe.
        # * services <~Array> - list of services you want to describe.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'services' <~Array> - The list of services described.
        #     * 'failures' <~Array> - The list of failures associated with the call (if any).
        def describe_services(params={})
          if services = params.delete('services')
            params.merge!(Fog::AWS.indexed_param('services.member', [*services]))
          end

          request({
            'Action'  => 'DescribeServices',
            :parser   => Fog::Parsers::AWS::ECS::DescribeServices.new
          }.merge(params))
        end
      end

      class Mock
        def describe_services(params={})
          response = Excon::Response.new
          response.status = 200

          cluster = params.delete('cluster') || 'default'
          services = params.delete('services')
          msg = 'InvalidParameterException => Services cannot be empty.'
          raise Fog::AWS::ECS::Error, msg unless services

          owner_id = Fog::AWS::Mock.owner_id

          if !cluster.match(/^arn:aws:ecs:.+:.+:cluster\/(.+)$/)
            cluster_path = "cluster/#{cluster}"
            cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          else
            cluster_arn = cluster
          end

          result = []
          ([*services].select { |s| s.match(/^arn:/) }).each do |ds|
            result.concat(self.data[:services].select do |sv|
              sv['serviceArn'].eql?(ds) && sv['clusterArn'].eql?(cluster_arn)
            end)
          end
          ([*services].select { |s| !s.match(/^arn:/) }).each do |ds|
            result.concat(self.data[:services].select do |sv|
              sv['serviceName'].eql?(ds) && sv['clusterArn'].eql?(cluster_arn)
            end)
          end

          response.body = {
            'DescribeServicesResult' => {
              'services' => result,
              'failures' => []
            },
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            }
          }
          response
        end
      end
    end
  end
end


