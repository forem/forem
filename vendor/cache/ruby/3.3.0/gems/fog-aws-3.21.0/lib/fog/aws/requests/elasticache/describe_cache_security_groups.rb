module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_security_groups'

        # Returns a list of CacheSecurityGroup descriptions
        #
        # === Parameters (optional)
        # * name <~String> - The name of an existing cache security group
        # * options <~Hash> (optional):
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
        def describe_cache_security_groups(name = nil, options = {})
          request({
            'Action'                  => 'DescribeCacheSecurityGroups',
            'CacheSecurityGroupName'  => name,
            'Marker'                  => options[:marker],
            'MaxRecords'              => options[:max_records],
            :parser => Fog::Parsers::AWS::Elasticache::DescribeSecurityGroups.new
          }.merge(options))
        end
      end

      class Mock
        def describe_cache_security_groups(name = nil, opts={})
          if name
            sec_group_set = [self.data[:security_groups][name]].compact
            raise Fog::AWS::Elasticache::NotFound.new("Security Group #{name} not found") if sec_group_set.empty?
          else
            sec_group_set = self.data[:security_groups].values
          end

          # TODO: refactor to not delete items that we're iterating over. Causes
          # model tests to fail (currently pending)
          sec_group_set.each do |sec_group|
            # TODO: refactor to not delete items that we're iterating over. Causes
            # model tests to fail (currently pending)
            sec_group["EC2SecurityGroups"].each do |ec2_secg|
              if ec2_secg["Status"] == "authorizing" || ec2_secg["Status"] == "revoking"
                ec2_secg[:tmp] ||= Time.now + Fog::Mock.delay * 2
                if ec2_secg[:tmp] <= Time.now
                  ec2_secg["Status"] = "authorized" if ec2_secg["Status"] == "authorizing"
                  ec2_secg.delete(:tmp)
                  sec_group["EC2SecurityGroups"].delete(ec2_secg) if ec2_secg["Status"] == "revoking"
                end
              end
            end
          end

          Excon::Response.new(
              {
                  :status => 200,
                  :body => {
                      "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
                      "CacheSecurityGroups" => sec_group_set
                  }
              }
          )
        end
      end
    end
  end
end
