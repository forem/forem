module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/modify_instance_groups'

        # modifies the number of nodes and configuration settings of an instance group..
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_ModifyInstanceGroups.html
        # ==== Parameters
        # * InstanceGroups <~InstanceGroupModifyConfig list> - Instance groups to change
        #   * InstanceCount <~Integer> - Target size for instance group
        #   * InstanceGroupId <~String> - Unique ID of the instance group to expand or shrink
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def modify_instance_groups(options={})
          if job_ids = options.delete('InstanceGroups')
            options.merge!(Fog::AWS.serialize_keys('InstanceGroups', job_ids))
          end

          request({
            'Action'  => 'ModifyInstanceGroups',
            :parser   => Fog::Parsers::AWS::EMR::ModifyInstanceGroups.new,
          }.merge(options))
        end
      end

      class Mock
        def modify_instance_groups(options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
