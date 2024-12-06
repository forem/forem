module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/add_instance_groups'

        # adds an instance group to a running cluster
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_AddInstanceGroups.html
        # ==== Parameters
        # * JobFlowId <~String> - Job flow in which to add the instance groups
        # * InstanceGroups<~Array> - Instance Groups to add
        #   * 'BidPrice'<~String> - Bid price for each Amazon EC2 instance in the instance group when launching nodes as Spot Instances, expressed in USD.
        #   * 'InstanceCount'<~Integer> - Target number of instances for the instance group
        #   * 'InstanceRole'<~String> - MASTER | CORE | TASK The role of the instance group in the cluster
        #   * 'InstanceType'<~String> - The Amazon EC2 instance type for all instances in the instance group
        #   * 'MarketType'<~String> - ON_DEMAND | SPOT Market type of the Amazon EC2 instances used to create a cluster node
        #   * 'Name'<~String> - Friendly name given to the instance group.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def add_instance_groups(job_flow_id, options={})
          if instance_groups = options.delete('InstanceGroups')
            options.merge!(Fog::AWS.indexed_param('InstanceGroups.member.%d', [*instance_groups]))
          end

          request({
            'Action'  => 'AddInstanceGroups',
            'JobFlowId' => job_flow_id,
            :parser   => Fog::Parsers::AWS::EMR::AddInstanceGroups.new,
          }.merge(options))
        end
      end

      class Mock
        def add_instance_groups(job_flow_id, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
