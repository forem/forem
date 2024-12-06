module Fog
  module AWS
    class Compute
      class KeyPair < Fog::Model
        identity  :name,        :aliases => 'keyName'

        attribute :fingerprint, :aliases => 'keyFingerprint'
        attribute :private_key, :aliases => 'keyMaterial'

        attr_accessor :public_key

        def destroy
          requires :name

          service.delete_key_pair(name)
          true
        end

        def save
          requires :name

          data = if public_key
            service.import_key_pair(name, public_key).body
          else
            service.create_key_pair(name).body
          end
          new_attributes = data.reject {|key,value| !['keyFingerprint', 'keyMaterial', 'keyName'].include?(key)}
          merge_attributes(new_attributes)
          true
        end

        def write(path="#{ENV['HOME']}/.ssh/fog_#{Fog.credential.to_s}_#{name}.pem")
          if writable?
            split_private_key = private_key.split(/\n/)
            File.open(path, "w") do |f|
              split_private_key.each {|line| f.puts line}
              f.chmod 0600
            end
            "Key file built: #{path}"
          else
            "Invalid private key"
          end
        end

        def writable?
          !!(private_key && ENV.key?('HOME'))
        end
      end
    end
  end
end
