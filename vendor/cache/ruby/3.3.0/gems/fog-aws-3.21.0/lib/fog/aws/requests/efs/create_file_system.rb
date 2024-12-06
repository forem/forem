module Fog
  module AWS
    class EFS
      class Real
        # Create a new, empty file system
        # http://docs.aws.amazon.com/efs/latest/ug/API_CreateFileSystem.html
        # ==== Parameters
        # * CreationToken <~String> - String of up to 64 ASCII characters. Amazon EFS uses this to ensure idempotent creation.
        # * PerformanceMode <~String> - (Optional) The PerformanceMode of the file system. We recommend generalPurpose performance mode for most file systems. File systems using the maxIO performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. This can't be changed after the file system has been created.
        # * Encrypted <~Boolean> - (Optional) A Boolean value that, if true, creates an encrypted file system. When creating an encrypted file system, you have the option of specifying a CreateFileSystem:KmsKeyId for an existing AWS Key Management Service (AWS KMS) customer master key (CMK). If you don't specify a CMK, then the default CMK for Amazon EFS, /aws/elasticfilesystem, is used to protect the encrypted file system. 
        # * KmsKeyId <~String> - (Optional) The ID of the AWS KMS CMK to be used to protect the encrypted file system. This parameter is only required if you want to use a non-default CMK. If this parameter is not specified, the default CMK for Amazon EFS is used. This ID can be in one of the following formats:
        #   - Key ID - A unique identifier of the key, for example, 1234abcd-12ab-34cd-56ef-1234567890ab.
        #   - ARN - An Amazon Resource Name (ARN) for the key, for example, arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab.
        #   - Key alias - A previously created display name for a key. For example, alias/projectKey1.
        #   - Key alias ARN - An ARN for a key alias, for example, arn:aws:kms:us-west-2:444455556666:alias/projectKey1.
        #   If KmsKeyId is specified, the CreateFileSystem:Encrypted parameter must be set to true.
        # ==== Returns
        # * response<~Excon::Response>
        #   * body<~Hash>
        def create_file_system(creation_token, options={})
          params = {
            :path             => "file-systems",
            :method           => 'POST',
            :expects          => 201,
            'CreationToken'   => creation_token,
            'PerformanceMode' => options[:peformance_mode] || 'generalPurpose',
            'Encrypted'       => options[:encrypted] || false
          }
          params[:kms_key_id] = options[:kms_key_id] if options.key?(:kms_key_id)
          request(params)
        end
      end

      class Mock
        def create_file_system(creation_token, options={})
          response = Excon::Response.new

          id = "fs-#{Fog::Mock.random_letters(8)}"
          file_system = {
            "OwnerId"              => Fog::AWS::Mock.owner_id,
            "CreationToken"        => creation_token,
            "PerformanceMode"      => options[:performance_mode] || "generalPurpose",
            "Encrypted"            => options[:encrypted] || false,
            "FileSystemId"         => id,
            "CreationTime"         => Time.now.to_i.to_f,
            "LifeCycleState"       => "creating",
            "NumberOfMountTargets" => 0,
            "SizeInBytes"          => {
              "Value"     => 1024,
              "Timestamp" => Time.now.to_i.to_f
            }
          }
          file_system[:kms_key_id] = options[:kms_key_id] if options.key?(:kms_key_id)

          self.data[:file_systems][id] = file_system
          response.body = file_system
          response.status = 201
          response
        end
      end
    end
  end
end
