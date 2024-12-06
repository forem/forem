module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketObjectVersions < Fog::Parsers::Base
          def reset
            @delete_marker = { 'Owner' => {} }
            @version = { 'Owner' => {} }

            @in_delete_marke = false
            @in_version = false

            @response = { 'Versions' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'DeleteMarker'
              @in_delete_marker = true
            when 'Version'
              @in_version = true
            end
          end

          def end_element(name)
            case name
            when 'DeleteMarker'
              @response['Versions'] << {'DeleteMarker' => @delete_marker }
              @delete_marker = { 'Owner' => {} }
              @in_delete_marker = false
            when 'Version'
              @response['Versions'] << {'Version' => @version }
              @version = { 'Owner' => {} }
              @in_version = false
            when 'DisplayName', 'ID'
              if @in_delete_marker
                @delete_marker
              elsif @in_version
                @version
              end['Owner'][name] = value
            when 'ETag'
              @version[name] = value.gsub('"', '')
            when 'IsLatest'
              if @in_delete_marker
                @delete_marker
              elsif @in_version
                @version
              end['IsLatest'] = if value == 'true'
                true
              else
                false
              end
            when 'IsTruncated'
              if value == 'true'
                @response['IsTruncated'] = true
              else
                @response['IsTruncated'] = false
              end
            when 'LastModified'
              if @in_delete_marker
                @delete_marker
              elsif @in_version
                @version
              end['LastModified'] = Time.parse(value)
            when 'MaxKeys'
              @response['MaxKeys'] = value.to_i
            when 'Size'
              @version['Size'] = value.to_i
            when 'Key', 'KeyMarker', 'Name', 'NextKeyMarker', 'NextVersionIdMarker', 'Prefix', 'StorageClass', 'VersionId', 'VersionIdMarker'
              if @in_delete_marker
                @delete_marker
              elsif @in_version
                @version
              else
                @response
              end[name] = value
            end
          end
        end
      end
    end
  end
end
