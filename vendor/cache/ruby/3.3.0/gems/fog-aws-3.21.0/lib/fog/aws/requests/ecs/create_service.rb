module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/create_service'

        # Runs and maintains a desired number of tasks from a specified task definition.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateService.html
        # ==== Parameters
        # * clientToken <~String> - unique, case-sensitive identifier you provide to ensure the idempotency of the request.
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that you want to run your service on.
        # * desiredCount <~Integer> - number of instantiations of the specified task definition that you would like to place and keep running on your cluster.
        # * loadBalancers <~Array> - list of load balancer objects, containing the load balancer name, the container name (as it appears in a container definition), and the container port to access from the load balancer.
        # * role <~String> - name or full Amazon Resource Name (ARN) of the IAM role that allows your Amazon ECS container agent to make calls to your load balancer on your behalf.
        # * serviceName <~String> - name of your service
        # * taskDefinition <~String> - family and revision (family:revision) or full Amazon Resource Name (ARN) of the task definition that you want to run in your service
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Service' <~Hash> - The full description of your new service
        def create_service(params={})
          if load_balancers = params.delete('loadBalancers')
            params.merge!(Fog::AWS.indexed_param('loadBalancers.member', [*load_balancers]))
          end
          request({
            'Action' => 'CreateService',
            :parser  => Fog::Parsers::AWS::ECS::CreateService.new
          }.merge(params))
        end
      end

      class Mock
        def create_service(params={})
          response = Excon::Response.new
          response.status = 200

          e = Fog::AWS::ECS::Error
          msg = 'ClientException => desiredCount cannot be empty.'
          raise e, msg unless desired_count = params['desiredCount']
          msg = 'ClientException => serviceName cannot be empty.'
          raise e unless service_name = params['serviceName']
          msg = 'ClientException => taskDefinition cannot be empty.'
          raise e unless task_definition = params['taskDefinition']

          owner_id = Fog::AWS::Mock.owner_id

          service_path = "service/#{service_name}"
          service_arn = Fog::AWS::Mock.arn('ecs', owner_id, service_path, region)

          cluster = params['cluster'] || 'default'
          if !cluster.match(/^arn:aws:ecs:.+:.+:cluster\/(.+)$/)
            cluster_path = "cluster/#{cluster}"
            cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          else
            cluster_arn = cluster
          end

          if params['role']
            role = params['role'] if params['role']
            if !role.match(/^arn:aws:iam:.*:.*:role\/(.+)$/)
              role_path = "role/#{role}"
              role_arn = Fog::AWS::Mock.arn('iam', owner_id, role_path, region)
            else
              role_arn = role
            end
          end

          if !task_definition.match(/^arn:aws:ecs:.+:.+:task-definition\/.+$/)
            task_def_path = "task-definition\/#{task_definition}"
            task_def_arn = Fog::AWS::Mock.arn('ecs', owner_id, task_def_path, region)
          else
            task_def_arn = task_definition
          end

          load_balancers = params['loadBalancers'] || []

          service = {
            'events'         => [],
            'serviceName'    => service_name,
            'serviceArn'     => service_arn,
            'taskDefinition' => task_def_arn,
            'clusterArn'     => cluster_arn,
            'status'         => 'ACTIVE',
            'roleArn'        => role_arn,
            'loadBalancers'  => [*load_balancers],
            'deployments'    => [],
            'desiredCount'   => desired_count,
            'pendingCount'   => 0,
            'runningCount'   => 0
          }

          service['deployments'] << {
            'updatedAt'      => Time.now.utc,
            'id'             => "ecs-svc/#{Fog::Mock.random_numbers(19)}",
            'taskDefinition' => task_def_arn,
            'status'         => 'PRIMARY',
            'desiredCount'   => desired_count,
            'createdAt'      => Time.now.utc,
            'pendingCount'   => 0,
            'runningCount'   => 0
          }

          self.data[:services] << service

          response.body = {
            'CreateServiceResult' => {
              'service' => service,
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
