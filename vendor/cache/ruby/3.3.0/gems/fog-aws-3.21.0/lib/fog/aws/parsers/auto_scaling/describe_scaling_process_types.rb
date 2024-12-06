module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeScalingProcessTypes < Fog::Parsers::Base
          def reset
            reset_process_type
            @results = { 'Processes' => [] }
            @response = { 'DescribeScalingProcessTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_process_type
            @process_type = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Processes'
              @in_processes = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_processes
                @results['Processes'] << @process_type
                reset_process_type
              end

            when 'ProcessName'
              @process_type[name] = value

            when 'Processes'
              @in_processes = false

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeScalingProcessTypesResponse'
              @response['DescribeScalingProcessTypesResult'] = @results
            end
          end
        end
      end
    end
  end
end
