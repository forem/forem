module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/run_task'

        # Start a task using random placement and the default Amazon ECS scheduler.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RunTask.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that you want to run your task on.
        # * count <~Integer> - number of instantiations of the specified task that you would like to place on your cluster.
        # * overrides <~Hash> - list of container overrides. 
        # * startedBy <~String> - optional tag specified when a task is started
        # * taskDefinition <~String> - family and revision (family:revision) or full ARN of the task definition that you want to run.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'tasks' <~Array> - full description of the tasks that were run.
        #     * 'failures' <~Array> - Any failed tasks from your RunTask action are listed here.
        def run_task(params={})
          if overrides = params.delete('overrides')
            serialized_overrides = {}
            if overrides.is_a?(Hash)
              overrides.each_pair do |k,v|
                serialized_overrides.merge!(Fog::AWS.serialize_keys(k, v))
              end
            end
            params.merge!('overrides' => serialized_overrides)
          end

          request({
            'Action'  => 'RunTask',
            :parser   => Fog::Parsers::AWS::ECS::RunTask.new
          }.merge(params))
        end
      end

      class Mock
        def run_task(params={})
          response = Excon::Response.new
          response.status = 200

          unless task_def_id = params.delete('taskDefinition')
            msg = 'ClientException => TaskDefinition cannot be empty.'
            raise Fog::AWS::ECS::Error, msg
          end

          begin
            result = describe_task_definition('taskDefinition' => task_def_id).body
            task_def = result["DescribeTaskDefinitionResult"]["taskDefinition"]
            task_def_arn = task_def["taskDefinitionArn"]
          rescue Fog::AWS::ECS::Error => e
            msg = 'ClientException => TaskDefinition not found.'
            raise Fog::AWS::ECS::Error, msg
          end

          if %w(count overrides).any? { |k| params.has_key?(k) }
            Fog::Logger.warning("you used parameters not mocked yet [light_black](#{caller.first})[/]")
            Fog::Mock.not_implemented
          end

          cluster_id = params.delete('cluster') || 'default'
          cluster_arn = nil
          owner_id = Fog::AWS::Mock.owner_id

          if cluster_id.match(/^arn:aws:ecs:.+:\d{1,12}:cluster\/(.+)$/)
            cluster_arn = cluster_id
          else
            cluster_path = "cluster/#{cluster_id}"
            cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          end

          task_path = "task/#{UUID.uuid}"
          task_arn = Fog::AWS::Mock.arn('ecs', owner_id, task_path, region)
          instance_path = "container-instance/#{UUID.uuid}"
          container_instance_arn = Fog::AWS::Mock.arn('ecs', owner_id, instance_path, region)

          containers = []
          task_def["containerDefinitions"].each do |c|
            container_path = "container/#{UUID.uuid}"
            containers << {
              'name'         => c['name'],
              'taskArn'      => task_arn,
              'lastStatus'   => 'PENDING',
              'containerArn' => Fog::AWS::Mock.arn('ecs', owner_id, container_path, region)
            }
          end

          task = {
            'clusterArn'           => cluster_arn,
            'desiredStatus'        => 'RUNNING',
            'taskDefinitionArn'    => task_def_arn,
            'lastStatus'           => 'PENDING',
            'taskArn'              => task_arn,
            'containerInstanceArn' => container_instance_arn,
            'containers'           => containers
          }
          self.data[:tasks] << task

          response.body = {
            'RunTaskResult' => {
              'failures' => [],
              'tasks' => [] << task
            },
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            }
          }
          response
        end
      end
    end
  end
end
