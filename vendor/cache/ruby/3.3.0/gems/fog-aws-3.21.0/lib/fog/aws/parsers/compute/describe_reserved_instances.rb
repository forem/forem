module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeReservedInstances < Fog::Parsers::Base
          def get_default_item
            {'tagSet' => {}, 'recurringCharges' => []}
          end

          def reset
            @context = []
            @contexts = ['reservedInstancesSet', 'recurringCharges', 'tagSet']
            @reserved_instance = get_default_item
            @response = { 'reservedInstancesSet' => [] }
            @charge = {}
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            case name
            when 'availabilityZone', 'instanceTenancy', 'instanceType', 'offeringType', 'productDescription', 'reservedInstancesId', 'scope', 'state'
              @reserved_instance[name] = value
            when 'duration', 'instanceCount'
              @reserved_instance[name] = value.to_i
            when 'fixedPrice', 'usagePrice'
              @reserved_instance[name] = value.to_f
            when *@contexts
              @context.pop
            when 'item'
              case @context.last
              when 'reservedInstancesSet'
                @response['reservedInstancesSet'] << @reserved_instance
                @reserved_instance = get_default_item
              when 'recurringCharges'
                @reserved_instance['recurringCharges'] << { 'frequency' => @charge['frequency'], 'amount' => @charge['amount'] }
                @charge = {}
              when 'tagSet'
                @reserved_instance['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              end
            when 'amount'
              case @context.last
              when 'reservedInstancesSet'
                @reserved_instance[name] = value.to_f
              when 'recurringCharges'
                @charge[name] = value.to_f
              end
            when 'frequency'
              @charge[name] = value
            when 'key', 'value'
              @tag[name] = value
            when 'requestId'
              @response[name] = value
            when 'start','end'
              @reserved_instance[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
