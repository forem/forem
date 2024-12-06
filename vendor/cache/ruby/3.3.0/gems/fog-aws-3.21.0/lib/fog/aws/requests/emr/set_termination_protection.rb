module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/set_termination_protection'

        # locks a job flow so the Amazon EC2 instances in the cluster cannot be terminated by user intervention.
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_SetTerminationProtection.html
        # ==== Parameters
        # * JobFlowIds <~String list> - list of strings that uniquely identify the job flows to protect
        # * TerminationProtected <~Boolean> - indicates whether to protect the job flow
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def set_termination_protection(is_protected, options={})
          if job_ids = options.delete('JobFlowIds')
            options.merge!(Fog::AWS.serialize_keys('JobFlowIds', job_ids))
          end
          request({
            'Action'  => 'SetTerminationProtection',
            'TerminationProtected' => is_protected,
            :parser   => Fog::Parsers::AWS::EMR::SetTerminationProtection.new,
          }.merge(options))
        end
      end

      class Mock
        def set_termination_protection(db_name, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
