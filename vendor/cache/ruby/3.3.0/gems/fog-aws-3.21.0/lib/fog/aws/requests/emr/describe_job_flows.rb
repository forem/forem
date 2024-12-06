module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/describe_job_flows'

        # returns a list of job flows that match all of the supplied parameters.
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_DescribeJobFlows.html
        # ==== Parameters
        # * CreatedAfter <~DateTime> - Return only job flows created after this date and time
        # * CreatedBefore <~DateTime> - Return only job flows created before this date and time
        # * JobFlowIds <~String list> - Return only job flows whose job flow ID is contained in this list
        # * JobFlowStates <~String list> - RUNNING | WAITING | SHUTTING_DOWN | STARTING Return only job flows whose state is contained in this list
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        # * JobFlows <~Array> - A list of job flows matching the parameters supplied.
        #   * AmiVersion <~String> - A list of bootstrap actions that will be run before Hadoop is started on the cluster nodes.
        #   * 'BootstrapActions'<~Array> - A list of the bootstrap actions run by the job flow
        #     * 'BootstrapConfig <~Array> - A description of the bootstrap action
        #       * 'Name' <~String> - The name of the bootstrap action
        #       * 'ScriptBootstrapAction' <~Array> - The script run by the bootstrap action.
        #         * 'Args' <~String list> - A list of command line arguments to pass to the bootstrap action script.
        #         * 'Path' <~String> - Location of the script to run during a bootstrap action.
        #   * 'ExecutionStatusDetail'<~Array> - Describes the execution status of the job flow
        #     * 'CreationDateTime <~DateTime> - The creation date and time of the job flow.
        #     * 'EndDateTime <~DateTime> - The completion date and time of the job flow.
        #     * 'LastStateChangeReason <~String> - Description of the job flow last changed state.
        #     * 'ReadyDateTime <~DateTime> - The date and time when the job flow was ready to start running bootstrap actions.
        #     * 'StartDateTime <~DateTime> - The start date and time of the job flow.
        #     * 'State <~DateTime> - COMPLETED | FAILED | TERMINATED | RUNNING | SHUTTING_DOWN | STARTING | WAITING | BOOTSTRAPPING The state of the job flow.
        #   * Instances <~Array> - A specification of the number and type of Amazon EC2 instances on which to run the job flow.
        #     * 'Ec2KeyName'<~String> - Specifies the name of the Amazon EC2 key pair that can be used to ssh to the master node as the user called "hadoop.
        #     * 'HadoopVersion'<~String> - "0.18" | "0.20" Specifies the Hadoop version for the job flow
        #     * 'InstanceCount'<~Integer> - The number of Amazon EC2 instances used to execute the job flow
        #     * 'InstanceGroups'<~Array> - Configuration for the job flow's instance groups
        #       * 'BidPrice' <~String> - Bid price for each Amazon EC2 instance in the instance group when launching nodes as Spot Instances, expressed in USD.
        #       * 'CreationDateTime' <~DateTime> - The date/time the instance group was created.
        #       * 'EndDateTime' <~DateTime> - The date/time the instance group was terminated.
        #       * 'InstanceGroupId' <~String> - Unique identifier for the instance group.
        #       * 'InstanceRequestCount'<~Integer> - Target number of instances for the instance group
        #       * 'InstanceRole'<~String> - MASTER | CORE | TASK The role of the instance group in the cluster
        #       * 'InstanceRunningCount'<~Integer> - Actual count of running instances
        #       * 'InstanceType'<~String> - The Amazon EC2 instance type for all instances in the instance group
        #       * 'LastStateChangeReason'<~String> - Details regarding the state of the instance group
        #       * 'Market'<~String> - ON_DEMAND | SPOT Market type of the Amazon EC2 instances used to create a cluster
        #       * 'Name'<~String> - Friendly name for the instance group
        #       * 'ReadyDateTime'<~DateTime> - The date/time the instance group was available to the cluster
        #       * 'StartDateTime'<~DateTime> - The date/time the instance group was started
        #       * 'State'<~String> - PROVISIONING | STARTING | BOOTSTRAPPING | RUNNING | RESIZING | ARRESTED | SHUTTING_DOWN | TERMINATED | FAILED | ENDED State of instance group
        #   * 'KeepJobFlowAliveWhenNoSteps' <~Boolean> - Specifies whether the job flow should terminate after completing all steps
        #   * 'MasterInstanceId'<~String> - The Amazon EC2 instance identifier of the master node
        #   * 'MasterInstanceType'<~String> - The EC2 instance type of the master node
        #   * 'MasterPublicDnsName'<~String> - The DNS name of the master node
        #   * 'NormalizedInstanceHours'<~Integer> - An approximation of the cost of the job flow, represented in m1.small/hours.
        #   * 'Placement'<~Array> - Specifies the Availability Zone the job flow will run in
        #     * 'AvailabilityZone' <~String> - The Amazon EC2 Availability Zone for the job flow.
        #   * 'SlaveInstanceType'<~String> - The EC2 instance type of the slave nodes
        #   * 'TerminationProtected'<~Boolean> - Specifies whether to lock the job flow to prevent the Amazon EC2 instances from being terminated by API call, user intervention, or in the event of a job flow error
        # * LogUri <~String> - Specifies the location in Amazon S3 to write the log files of the job flow. If a value is not provided, logs are not created
        # * Name <~String> - The name of the job flow
        # * Steps <~Array> - A list of steps to be executed by the job flow
        #   * 'ExecutionStatusDetail'<~Array> - Describes the execution status of the job flow
        #     * 'CreationDateTime <~DateTime> - The creation date and time of the job flow.
        #     * 'EndDateTime <~DateTime> - The completion date and time of the job flow.
        #     * 'LastStateChangeReason <~String> - Description of the job flow last changed state.
        #     * 'ReadyDateTime <~DateTime> - The date and time when the job flow was ready to start running bootstrap actions.
        #     * 'StartDateTime <~DateTime> - The start date and time of the job flow.
        #     * 'State <~DateTime> - COMPLETED | FAILED | TERMINATED | RUNNING | SHUTTING_DOWN | STARTING | WAITING | BOOTSTRAPPING The state of the job flow.
        #   * StepConfig <~Array> - The step configuration
        #     * 'ActionOnFailure'<~String> - TERMINATE_JOB_FLOW | CANCEL_AND_WAIT | CONTINUE Specifies the action to take if the job flow step fails
        #     * 'HadoopJarStep'<~Array> - Specifies the JAR file used for the job flow step
        #       * 'Args'<~String list> - A list of command line arguments passed to the JAR file's main function when executed.
        #       * 'Jar'<~String> - A path to a JAR file run during the step.
        #       * 'MainClass'<~String> - The name of the main class in the specified Java file. If not specified, the JAR file should specify a Main-Class in its manifest file
        #       * 'Properties'<~Array> - A list of Java properties that are set when the step runs. You can use these properties to pass key value pairs to your main function
        #         * 'Key'<~String> - The unique identifier of a key value pair
        #         * 'Value'<~String> - The value part of the identified key
        #     * 'Name'<~String> - The name of the job flow step
        def describe_job_flows(options={})
          if job_ids = options.delete('JobFlowIds')
            options.merge!(Fog::AWS.serialize_keys('JobFlowIds', job_ids))
          end

          if job_states = options.delete('JobFlowStates')
            options.merge!(Fog::AWS.serialize_keys('JobFlowStates', job_states))
          end

          request({
            'Action'  => 'DescribeJobFlows',
            :parser   => Fog::Parsers::AWS::EMR::DescribeJobFlows.new,
          }.merge(options))
        end
      end

      class Mock
        def describe_job_flows(db_name, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
