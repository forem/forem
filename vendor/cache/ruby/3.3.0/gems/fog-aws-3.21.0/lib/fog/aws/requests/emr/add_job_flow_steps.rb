module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/add_job_flow_steps'

        # adds new steps to a running job flow.
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_AddJobFlowSteps.html
        # ==== Parameters
        # * JobFlowId <~String> - A string that uniquely identifies the job flow
        # * Steps <~Array> - A list of steps to be executed by the job flow
        #   * 'ActionOnFailure'<~String> - TERMINATE_JOB_FLOW | CANCEL_AND_WAIT | CONTINUE Specifies the action to take if the job flow step fails
        #   * 'HadoopJarStep'<~Array> - Specifies the JAR file used for the job flow step
        #     * 'Args'<~String list> - A list of command line arguments passed to the JAR file's main function when executed.
        #     * 'Jar'<~String> - A path to a JAR file run during the step.
        #     * 'MainClass'<~String> - The name of the main class in the specified Java file. If not specified, the JAR file should specify a Main-Class in its manifest file
        #     * 'Properties'<~Array> - A list of Java properties that are set when the step runs. You can use these properties to pass key value pairs to your main function
        #       * 'Key'<~String> - The unique identifier of a key value pair
        #       * 'Value'<~String> - The value part of the identified key
        #   * 'Name'<~String> - The name of the job flow step
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def add_job_flow_steps(job_flow_id, options={})
          if steps = options.delete('Steps')
            options.merge!(Fog::AWS.serialize_keys('Steps', steps))
          end

          request({
            'Action'  => 'AddJobFlowSteps',
            'JobFlowId' => job_flow_id,
            :parser   => Fog::Parsers::AWS::EMR::AddJobFlowSteps.new,
          }.merge(options))
        end
      end

      class Mock
        def add_job_flow_steps(db_name, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
