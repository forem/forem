module Fog
  module AWS
    class EFS
      class Real
        # Describe all or specified elastic file systems
        # http://docs.aws.amazon.com/efs/latest/ug/API_DescribeFileSystems.html
        # ==== Parameters
        # * CreationToken <~String> - (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
        # * FileSystemId <~String> - (Optional) ID of the file system whose description you want to retrieve (String).
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def describe_file_systems(options={})
          params = {}
          if options[:marker]
            params['Marker'] = options[:marker]
          end
          if options[:max_records]
            params['MaxRecords'] = options[:max_records]
          end
          if options[:id]
            params['FileSystemId'] = options[:id]
          end
          if options[:creation_token]
            params['CreationToken'] = options[:creation_token]
          end

          request({
            :path => "file-systems"
          }.merge(params))
        end
      end

      class Mock
        def describe_file_systems(options={})
          response = Excon::Response.new

          file_systems = if id = options[:id]
                           if fs = self.data[:file_systems][id]
                             [fs]
                           else
                             raise Fog::AWS::EFS::NotFound.new("invalid file system ID: #{id}")
                           end
                         elsif creation_token = options[:creation_token]
                           fs = self.data[:file_systems].values.detect { |file_system| file_system["CreationToken"] == creation_token }
                           [fs]
                         else
                           self.data[:file_systems].values
                         end

          file_systems.each do |file_system|
            file_system['LifeCycleState'] = 'available'
            self.data[:file_systems][file_system['FileSystemId']] = file_system
          end

          response.body = {"FileSystems" => file_systems}
          response
        end
      end
    end
  end
end
