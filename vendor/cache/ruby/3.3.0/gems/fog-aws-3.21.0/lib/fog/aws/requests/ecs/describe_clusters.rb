module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/describe_clusters'

        # Describes one or more of your clusters.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeClusters.html
        # ==== Parameters
        # * clusters <~Array> - list of cluster names or full cluster Amazon Resource Name (ARN) entries
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'clusters' <~Array> - The list of clusters
        #     * 'failures' <~Array> - The list of failures (if any)
        def describe_clusters(params={})
          if members = params.delete('clusters')
            params.merge!(Fog::AWS.indexed_param('clusters.member', [*members]))
          end

          request({
            'Action'  => 'DescribeClusters',
            :parser   => Fog::Parsers::AWS::ECS::DescribeClusters.new
          }.merge(params))
        end
      end

      class Mock
        def describe_clusters(params={})
          response = Excon::Response.new
          response.status = 200

          members = params.delete('clusters')
          members = 'default' unless members
          clusters = []
          failures = []

          [*members].each do |c|
            if match = c.match(/^arn:aws:ecs:.+:\d{1,12}:cluster\/(.+)$/)
              result = self.data[:clusters].select { |cl| cl['clusterArn'].eql?(c) }
            else
              result = self.data[:clusters].select { |cl| cl['clusterName'].eql?(c) }
            end
            if result.empty?
              cluster_name = match[1] if match
              cluster_name = c        unless match
              failures << { 'name' => cluster_name }
            else
              clusters << result.first
            end
          end

          owner_id = Fog::AWS::Mock.owner_id

          failures.map! do |f|
            {
              'arn' => Fog::AWS::Mock.arn('ecs', owner_id, "cluster/#{f['name']}", region),
              'reason' => 'MISSING'
            }
          end
          clusters.map! do |c|
            {
              'clusterName' => c['clusterName'],
              'clusterArn'  => c['clusterArn'],
              'status'      => c['status']
            }
          end

          response.body = {
            'DescribeClustersResult' => {
              'failures' => failures,
              'clusters' => clusters
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
