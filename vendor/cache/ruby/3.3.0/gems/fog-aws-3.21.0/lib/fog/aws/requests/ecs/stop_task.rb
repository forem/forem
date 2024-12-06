module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/stop_task'

        # Stops a running task.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_StopTask.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that hosts the task you want to stop.
        # * task <~String> - task UUIDs or full Amazon Resource Name (ARN) entry of the task you would like to stop.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Task' <~Hash> - The full description of the stopped task.
        def stop_task(params={})
          request({
            'Action' => 'StopTask',
            :parser  => Fog::Parsers::AWS::ECS::StopTask.new
          }.merge(params))
        end
      end

      class Mock
        def stop_task(params={})
          response = Excon::Response.new
          response.status = 200

          unless task_id = params.delete('task')
            msg = "InvalidParameterException => Task can not be blank."
            raise Fog::AWS::ECS::Error, msg
          end

          if cluster = params.delete('cluster')
            Fog::Logger.warning("you used parameters not mocked yet [light_black](#{caller.first})[/]")
          end

          if match = task_id.match(/^arn:aws:ecs:.+:\d{1,12}:task\/(.+)$/)
            i = self.data[:tasks].index { |t| t['taskArn'].eql?(task_id) }
          else
            i = self.data[:tasks].index { |t| t['taskArn'].match(/#{task_id}$/) }
          end

          msg = "ClientException => The referenced task was not found."
          raise Fog::AWS::ECS::Error, msg unless i

          task = self.data[:tasks][i]
          task['desiredStatus'] = 'STOPPED'
          self.data[:tasks].delete_at(i)

          response.body = {
            'StopTaskResult' => {
              'task' => task
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
