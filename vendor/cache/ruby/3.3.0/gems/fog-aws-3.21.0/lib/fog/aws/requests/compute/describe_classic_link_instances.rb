module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_classic_link_instances'
        # Describes one or more of your linked EC2-Classic instances. This request only returns information about EC2-Classic instances linked to a VPC through ClassicLink; you cannot use this request to return information about other instances.
        #
        # ==== Parameters
        # * options<~Hash>
        #   * instance_ids<~Array>  - An array of instance ids to restruct the results to
        #   * filters<~Hash> - Filters to restrict the results to. Recognises vpc-id, group-id, instance-id in addition
        #                      to tag-key, tag-value and tag:key
        #   * max_results
        #   * next_token
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'instancesSet'<~Array>          - array of ClassicLinkInstance
        #   * 'vpcId'<~String>
        #   * 'instanceId'<~String>
        #   * 'tagSet'<~Hash>
        #   * 'groups'<~Array>
        #     * groupId <~String>
        #     * groupName <~String>
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeClassicLinkInstances.html
        def describe_classic_link_instances(options={})
          params = {}
          params['MaxResults'] = options[:max_results] if options[:max_results]
          params['NextToken'] = options[:next_token] if options[:next_token]
          params.merge!(Fog::AWS.indexed_param('InstanceId', options[:instance_ids])) if options[:instance_ids]
          params.merge!(Fog::AWS.indexed_filters(options[:filters])) if options[:filters]
          request({
            'Action'    => 'DescribeClassicLinkInstances',
            :parser     => Fog::Parsers::AWS::Compute::DescribeClassicLinkInstances.new
          }.merge(params))
        end
      end

      class Mock
        def describe_classic_link_instances(options={})
          response = Excon::Response.new
          instances = self.data[:instances].values.select {|instance| instance['classicLinkVpcId']}
          if options[:filters]
            instances = apply_tag_filters(instances, options[:filters], 'instanceId')
            instances = instances.select {|instance| instance['classicLinkVpcId'] == options[:filters]['vpc-id']} if options[:filters]['vpc-id']
            instances = instances.select {|instance| instance['instanceId'] == options[:filters]['instance-id']} if options[:filters]['instance-id']
            instances = instances.select {|instance| instance['classicLinkSecurityGroups'].include?(options[:filters]['group-id'])} if options[:filters]['group-id']
          end
          instances = instances.select {|instance| options[:instance_ids].include?(instance['instanceId'])} if options[:instance_ids]



          response.status = 200
          instance_data = instances.collect do |instance| 
            groups = self.data[:security_groups].values.select {|data| instance['classicLinkSecurityGroups'].include?(data['groupId'])}
            {
              'instanceId' => instance['instanceId'],
              'vpcId' => instance['classicLinkVpcId'],
              'groups' => groups.collect {|group| {'groupId' => group['groupId'], 'groupName' => group['groupName']}},
              'tagSet' => self.data[:tag_sets][instance['instanceId']] || {}
            }
          end
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'instancesSet' => instance_data
          }
          response
        end
      end
    end
  end
end
