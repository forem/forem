module Fog
  module AWS
    class EMR
      class Real
        require 'fog/aws/parsers/emr/run_job_flow'

        # creates and starts running a new job flow
        # http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/API_RunJobFlow.html
        # ==== Parameters
        # * AdditionalInfo <~String> - A JSON string for selecting additional features.
        # * BootstrapActions <~Array> - A list of bootstrap actions that will be run before Hadoop is started on the cluster nodes.
        #   * 'Name'<~String> - The name of the bootstrap action
        #   * 'ScriptBootstrapAction'<~Array> - The script run by the bootstrap action
        #     * 'Args' <~Array> - A list of command line arguments to pass to the bootstrap action script
        #     * 'Path' <~String> - Location of the script to run during a bootstrap action. Can be either a location in Amazon S3 or on a local file system.
        # * Instances <~Array> - A specification of the number and type of Amazon EC2 instances on which to run the job flow.
        #   * 'Ec2KeyName'<~String> - Specifies the name of the Amazon EC2 key pair that can be used to ssh to the master node as the user called "hadoop.
        #   * 'HadoopVersion'<~String> - "0.18" | "0.20" Specifies the Hadoop version for the job flow
        #   * 'InstanceCount'<~Integer> - The number of Amazon EC2 instances used to execute the job flow
        #   * 'InstanceGroups'<~Array> - Configuration for the job flow's instance groups
        #     * 'BidPrice' <~String> - Bid price for each Amazon EC2 instance in the instance group when launching nodes as Spot Instances, expressed in USD.
        #     * 'InstanceCount'<~Integer> - Target number of instances for the instance group
        #     * 'InstanceRole'<~String> - MASTER | CORE | TASK The role of the instance group in the cluster
        #     * 'InstanceType'<~String> - The Amazon EC2 instance type for all instances in the instance group
        #     * 'MarketType'<~String> - ON_DEMAND | SPOT Market type of the Amazon EC2 instances used to create a cluster node
        #     * 'Name'<~String> - Friendly name given to the instance group.
        #   * 'KeepJobFlowAliveWhenNoSteps' <~Boolean> - Specifies whether the job flow should terminate after completing all steps
        #   * 'MasterInstanceType'<~String> - The EC2 instance type of the master node
        #   * 'Placement'<~Array> - Specifies the Availability Zone the job flow will run in
        #     * 'AvailabilityZone' <~String> - The Amazon EC2 Availability Zone for the job flow.
        #   * 'SlaveInstanceType'<~String> - The EC2 instance type of the slave nodes
        #   * 'TerminationProtected'<~Boolean> - Specifies whether to lock the job flow to prevent the Amazon EC2 instances from being terminated by API call, user intervention, or in the event of a job flow error
        # * LogUri <~String> - Specifies the location in Amazon S3 to write the log files of the job flow. If a value is not provided, logs are not created
        # * Name <~String> - The name of the job flow
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
        def run_job_flow(name, options={})
          if bootstrap_actions = options.delete('BootstrapActions')
            options.merge!(Fog::AWS.serialize_keys('BootstrapActions', bootstrap_actions))
          end

          if instances = options.delete('Instances')
            options.merge!(Fog::AWS.serialize_keys('Instances', instances))
          end

          if steps = options.delete('Steps')
            options.merge!(Fog::AWS.serialize_keys('Steps', steps))
          end

          request({
            'Action'  => 'RunJobFlow',
            'Name' => name,
            :parser   => Fog::Parsers::AWS::EMR::RunJobFlow.new,
          }.merge(options))
        end

        def run_hive(name, options={})
          steps = []
          steps << {
            'Name' => 'Setup Hive',
            'HadoopJarStep' => {
              'Jar' => 's3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar',
              'Args' => ['s3://us-east-1.elasticmapreduce/libs/hive/hive-script', '--base-path', 's3://us-east-1.elasticmapreduce/libs/hive/', '--install-hive']},
            'ActionOnFailure' => 'TERMINATE_JOB_FLOW'
          }

          # To add a configuration step to the Hive flow, see the step below
          # steps << {
          #   'Name' => 'Install Hive Site Configuration',
          #   'HadoopJarStep' => {
          #     'Jar' => 's3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar',
          #     'Args' => ['s3://us-east-1.elasticmapreduce/libs/hive/hive-script', '--base-path',  's3://us-east-1.elasticmapreduce/libs/hive/', '--install-hive-site', '--hive-site=s3://my.bucket/hive/hive-site.xml']},
          #   'ActionOnFailure' => 'TERMINATE_JOB_FLOW'
          # }
          options['Steps'] = steps

          if not options['Instances'].nil?
            options['Instances']['KeepJobFlowAliveWhenNoSteps'] = true
          end

          run_job_flow name, options
        end
      end

      class Mock
        def run_job_flow(db_name, options={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
