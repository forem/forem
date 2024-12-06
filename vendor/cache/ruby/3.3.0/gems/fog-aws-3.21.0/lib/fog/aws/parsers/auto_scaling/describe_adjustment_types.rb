module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeAdjustmentTypes < Fog::Parsers::Base
          def reset
            reset_adjustment_type
            @results = { 'AdjustmentTypes' => [] }
            @response = { 'DescribeAdjustmentTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_adjustment_type
            @adjustment_type = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'AdjustmentTypes'
              @in_adjustment_types = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_adjustment_types
                @results['AdjustmentTypes'] << @adjustment_type
                reset_adjustment_type
              end

            when 'AdjustmentType'
              @adjustment_type[name] = value

            when 'AdjustmentTypes'
              @in_adjustment_types = false

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeAdjustmentTypesResponse'
              @response['DescribeAdjustmentTypesResult'] = @results
            end
          end
        end
      end
    end
  end
end
