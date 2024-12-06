module Fog
  module Parsers
    module AWS
      module IAM
        class ListPolicyVersions < Fog::Parsers::Base
          def reset
            super
            @stack = []
            @response = { 'Versions' => [], 'Marker' => '', 'IsTruncated' => false }
          end

          def start_element(name,attrs = [])
            case name
            when 'Versions'
              @stack << name
            when 'member'
              if @stack.last == 'Versions'
                @version = {}
              end
            end
            super
          end

          def end_element(name)
            case name
            when 'member'
              @response['Versions'] << @version
              @version = {}
            when 'IsTruncated'
              response[name] = (value == 'true')
            when 'Marker', 'RequestId'
              @response[name] = value
            end
            super
          end
          
          def end_element(name)
            case name
            when 'VersionId'
              @version[name] = value
            when 'CreateDate'
              @version[name] = Time.parse(value)
            when 'IsDefaultVersion'
              @version[name] = (value == 'true')
            when 'Versions'
              if @stack.last == 'Versions'
                @stack.pop
              end
            when 'member'
              if @stack.last == 'Versions'
                finished_version(@version)
                @version = nil
              end
            end
          end
          
          def finished_version(version)
            @response['Versions'] << version
          end
        end
      end
    end
  end
end
