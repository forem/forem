module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/terminate_job_flows'

        # shuts a list of job flows down.
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_TerminateJobFlows.html
        # ==== Parameters
        # * JobFlowIds <~String list> - list of strings that uniquely identify the job flows to protect
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def terminate_job_flows(options={})
          if job_ids = options.delete('JobFlowIds')
            options.merge!(Fog::AWS.serialize_keys('JobFlowIds', job_ids))
          end
          request({
            'Action'  => 'TerminateJobFlows',
            :parser   => Fog::Parsers::AWS::EMR::TerminateJobFlows.new,
          }.merge(options))
        end
      end

      class Mock
        def terminate_job_flows(db_name, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
