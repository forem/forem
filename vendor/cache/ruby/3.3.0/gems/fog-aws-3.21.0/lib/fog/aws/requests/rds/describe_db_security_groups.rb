module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_security_groups'

        # Describe all or specified db security groups
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/index.html?API_DescribeDBSecurityGroups.html
        # ==== Parameters
        # * DBSecurityGroupName <~String> - The name of the DB Security Group to return details for.
        # * Marker               <~String> - An optional marker provided in the previous DescribeDBInstances request
        # * MaxRecords           <~Integer> - Max number of records to return (between 20 and 100)
        # Only one of DBInstanceIdentifier or DBSnapshotIdentifier can be specified
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_db_security_groups(opts={})
          opts = {'DBSecurityGroupName' => opts} if opts.is_a?(String)

          request({
            'Action'  => 'DescribeDBSecurityGroups',
            :parser   => Fog::Parsers::AWS::RDS::DescribeDBSecurityGroups.new
          }.merge(opts))
        end
      end

      class Mock
        def describe_db_security_groups(opts={})
          response = Excon::Response.new
          sec_group_set = []
          if opts.is_a?(String)
            sec_group_name = opts
            if sec_group = self.data[:security_groups][sec_group_name]
              sec_group_set << sec_group
            else
              raise Fog::AWS::RDS::NotFound.new("Security Group #{sec_group_name} not found")
            end
          else
            sec_group_set = self.data[:security_groups].values
          end

          # TODO: refactor to not delete items that we're iterating over. Causes
          # model tests to fail (currently pending)
          sec_group_set.each do |sec_group|
            sec_group["IPRanges"].each do |iprange|
              if iprange["Status"] == "authorizing" || iprange["Status"] == "revoking"
                iprange[:tmp] ||= Time.now + Fog::Mock.delay * 2
                if iprange[:tmp] <= Time.now
                  iprange["Status"] = "authorized" if iprange["Status"] == "authorizing"
                  iprange.delete(:tmp)
                  sec_group["IPRanges"].delete(iprange) if iprange["Status"] == "revoking"
                end
              end
            end

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

          response.status = 200
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "DescribeDBSecurityGroupsResult" => { "DBSecurityGroups" => sec_group_set }
          }
          response
        end
      end
    end
  end
end
