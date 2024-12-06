module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/start_task'

        # Starts a new task from the specified task definition on the specified container instance or instances.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_StartTask.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that you want to start your task on.
        # * containerInstances <~Array> - container instance UUIDs or full ARN entries for the container instances on which you would like to place your task.
        # * overrides <~Hash> - list of container overrides.
        # * startedBy <~String> - optional tag specified when a task is started
        # * taskDefinition <~String> - family and revision (family:revision) or full ARN of the task definition that you want to start.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'tasks' <~Array> - full description of the tasks that were started.
        #     * 'failures' <~Array> - Any failed tasks from your StartTask action are listed here.
        def start_task(params={})
          if container_instances = params.delete('containerInstances')
            params.merge!(Fog::AWS.indexed_param('containerInstances.member', [*container_instances]))
          end

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
            'Action'  => 'StartTask',
            :parser   => Fog::Parsers::AWS::ECS::StartTask.new
          }.merge(params))
        end
      end

      class Mock
        def start_task(params={})
          response = Excon::Response.new
          response.status = 200

          unless task_def_id = params.delete('taskDefinition')
            msg = 'ClientException => TaskDefinition cannot be empty.'
            raise Fog::AWS::ECS::Error, msg
          end

          unless instances_id = params.delete('containerInstances')
            msg = 'ClientException => Container instances cannot be empty.'
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

          if %w(startedBy overrides).any? { |k| params.has_key?(k) }
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

          instance_id = [*instances_id].first
          if instance_id.match(/^arn:aws:ecs:.+:\d{1,12}:container-instance\/(.+)$/)
            container_instance_arn = instance_id
          else
            instance_path = "container-instance/#{instance_id}"
            container_instance_arn = Fog::AWS::Mock.arn('ecs', owner_id, instance_path, region)
          end

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
            'StartTaskResult' => {
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
