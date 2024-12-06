module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        class BaseParser < Fog::Parsers::Base
          def initialize(result_name)
            @result_name = result_name # Set before super, since super calls reset
            super()
            @tags = {}
            @list_tags = {}
          end

          def reset
            @response = { @result_name => {}, 'ResponseMetadata' => {} }
            # Push root object to top of stack
            @parse_stack = [ { :type => :object, :value => @response[@result_name]} ]
          end

          def tag name, *traits
            if traits.delete(:list)
              @list_tags[name] = true
            end

            if traits.length == 1
              @tags[name] = traits.last
            else
              raise "Too many traits specified, only specify :list or a type"
            end
          end

          def start_element(name, attrs = [])
            super
            if name == 'member'
              if @parse_stack.last[:type] == :object
                @parse_stack.last[:value] << {} # Push any empty object
              end
            elsif @list_tags.key?(name)
              set_value(name, [], :array) # Set an empty array
              @parse_stack.push({ :type => @tags[name], :value => get_parent[name] })
            elsif @tags[name] == :object
              set_value(name, {}, :object)
              @parse_stack.push({ :type => @tags[name], :value => get_parent[name] })
            end
          end

          def end_element(name)
            case name
              when 'member'
                if @parse_stack.last[:type] != :object
                  @parse_stack.last[:value] << value
                end
              when 'RequestId'
                @response['ResponseMetadata'][name] = value
              else
                if @list_tags.key?(name) || @tags[name] == :object
                  @parse_stack.pop()
                elsif @tags.key?(name)
                  set_value(name, value, @tags[name])
                end
            end
          end

          def get_parent
            parent = @parse_stack.last[:value]
            parent.is_a?(Array) ? parent.last : parent
          end

          def set_value(name, value, type)
            case type
              when :datetime
                get_parent[name] = Time.parse value
              when :boolean
                get_parent[name] = value == "true" # True only if value is true
              when :integer
                get_parent[name] = value.to_i
              else
                get_parent[name] = value
            end
          end
        end
      end
    end
  end
end
