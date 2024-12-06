module Fog
  module AWS
    class Support < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :host, :path, :port, :scheme, :instrumentor, :instrumentor_name, :region, :persistent, :aws_session_token, :aws_credentials_expire_at, :sts_endpoint

      model_path 'fog/aws/models/support'
      request_path 'fog/aws/requests/support'

      collection :flagged_resources
      collection :trusted_advisor_checks

      model :flagged_resource
      model :trusted_advisor_check

      request :describe_trusted_advisor_checks
      request :describe_trusted_advisor_check_result

      class Mock
        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              tac_id = Fog::Mock.random_hex(5)
              region_hash[key] = {
                :trusted_advisor_checks => {
                  tac_id => {
                    "category"=>"cost_optimizing",
                    "description"=>"Checks the Amazon Elastic Compute Cloud (Amazon EC2) instances that were running at any time during the last 14 days and alerts you if the daily CPU utilization was 10% or less and network I/O was 5 MB or less on 4 or more days. Running instances generate hourly usage charges. Although some scenarios can result in low utilization by design, you can often lower your costs by managing the number and size of your instances.\n<br><br>\nEstimated monthly savings are calculated by using the current usage rate for On-Demand Instances and the estimated number of days the instance might be underutilized. Actual savings will vary if you are using Reserved Instances or Spot Instances, or if the instance is not running for a full day. To get daily utilization data, download the report for this check. \n<br>\n<br>\n<b>Alert Criteria</b><br>\nYellow: An instance had 10% or less daily average CPU utilization and 5 MB or less network I/O on at least 4 of the previous 14 days.<br>\n<br>\n<b>Recommended Action</b><br>\nConsider stopping or terminating instances that have low utilization, or scale the number of instances by using Auto Scaling. For more information, see <a href=\"http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Stop_Start.html\" target=\"_blank\">Stop and Start Your Instance</a>, <a href=\"http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html\" target=\"_blank\">Terminate Your Instance</a>, and <a href=\"http://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/WhatIsAutoScaling.html\" target=\"_blank\">What is Auto Scaling?</a><br>\n<br>\n<b>Additional Resources</b><br>\n<a href=\"http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-monitoring.html\" target=\"_blank\">Monitoring Amazon EC2</a><br>\n<a href=\"http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html\" target=\"_blank\">Instance Metadata and User Data</a><br>\n<a href=\"http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/Welcome.html\" target=\"_blank\">Amazon CloudWatch Developer Guide</a><br>\n<a href=\"http://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/WhatIsAutoScaling.html\" target=\"_blank\">Auto Scaling Developer Guide</a>",
                    "id"=>tac_id,
                    "metadata"=>["Region/AZ", "Instance ID", "Instance Name", "Instance Type", "Estimated Monthly Savings", "Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7", "Day 8", "Day 9", "Day 10", "Day 11", "Day 12", "Day 13", "Day 14", "14-Day Average CPU Utilization", "14-Day Average Network I/O", "Number of Days Low Utilization"],
                    "name"=>"Low Utilization Amazon EC2 Instances"
                  }
                },
                :trusted_advisor_check_results => {
                  tac_id => {
                    'checkId'          => tac_id,
                    'status'           => "warning",
                    'timestamp'        => "2016-09-18T13:19:35Z",
                    'resourcesSummary' => {
                      "resourcesFlagged"    => 40,
                      "resourcesIgnored"    => 0,
                      "resourcesProcessed"  => 47,
                      "resourcesSuppressed" => 0
                    },
                    'categorySpecificSummary' => {
                      "costOptimizing" => {
                        "estimatedMonthlySavings"        => 4156.920000000003,
                        "estimatedPercentMonthlySavings" => 0.9918398900532555
                      }
                    },
                    'flaggedResources' => [{
                      "region"       => "us-west-2",
                      "resourceId"   => Fog::Mock.random_hex(22),
                      "status"       => "warning",
                      "isSuppressed" => false,
                      "metadata"     => ["us-west-2a", "i-#{Fog::Mock.random_hex(5)}", "instance_tags", "m3.large", "$95.76", "2.3%  0.23MB", "2.3%  0.20MB", "2.3%  0.21MB", "2.4%  0.28MB", "2.3%  0.20MB", "2.3%  0.20MB", "2.3%  0.20MB", "2.3%  0.20MB", "2.3%  0.20MB", "2.3%  0.20MB", "2.6%  0.54MB", "2.4%  0.31MB", "2.3%  0.21MB", "2.3%  0.20MB", "2.3%", "0.24MB", "14 days"]
                    }]
                  }
                }
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def reset
          self.class.reset
        end

        attr_accessor :region

        def initialize(options={})
          @region = 'us-east-1'
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def initialize(options={})
          @connection_options = options[:connection_options] || {}
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.support'

          @region     = 'us-east-1'
          @host       = options[:host]       || "support.#{@region}.amazonaws.com"
          @path       = options[:path]       || "/"
          @port       = options[:port]       || 443
          @scheme     = options[:scheme]     || "https"
          @persistent = options[:persistent] || false
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @version    = options[:version]    || '2013-04-15'

          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        def setup_credentials(options)
          @aws_access_key_id         = options[:aws_access_key_id]
          @aws_secret_access_key     = options[:aws_secret_access_key]
          @aws_session_token         = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          #global services that have no region are signed with the us-east-1 region
          #the only exception is GovCloud, which requires the region to be explicitly specified as us-gov-west-1
          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'support')
        end

        def request(params)
          refresh_credentials_if_expired
          idempotent   = params.delete(:idempotent)
          parser       = params.delete(:parser)
          action       = params.delete('Action')
          request_body = Fog::JSON.encode(params)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            {
              'Content-Type' => "application/x-amz-json-1.1",
              "X-Amz-Target" => "AWSSupport_#{@version.gsub("-", "")}.#{action}"
            },
            {
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => @version,
              :signer             => @signer,
              :aws_session_token  => @aws_session_token,
              :method             => 'POST',
              :body               => request_body
            }
          )

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser)
            end
          else
            _request(body, headers, idempotent, parser)
          end
        end

        def _request(body, headers, idempotent, parser)
          response = @connection.request({
            :body       => body,
            :expects    => 200,
            :idempotent => idempotent,
            :headers    => headers,
            :method     => 'POST',
            :parser     => parser
          })
          response.body = Fog::JSON.decode(response.body)
          response
        end
      end
    end
  end
end
