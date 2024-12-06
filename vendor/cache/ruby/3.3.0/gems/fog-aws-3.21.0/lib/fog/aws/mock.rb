module Fog
  module AWS
    class Mock
      def self.arn(vendor, account_id, path, region = nil)
        "arn:aws:#{vendor}:#{region}:#{account_id}:#{path}"
      end

      def self.availability_zone(region)
        "#{region}#{Fog::Mock.random_selection('abcd', 1)}"
      end

      def self.box_usage
        sprintf("%0.10f", rand / 100).to_f
      end

      def self.console_output
        # "[ 0.000000] Linux version 2.6.18-xenU-ec2-v1.2 (root@domU-12-31-39-07-51-82) (gcc version 4.1.2 20070626 (Red Hat 4.1.2-13)) #2 SMP Wed Aug 19 09:04:38 EDT 2009"
        Base64.decode64("WyAwLjAwMDAwMF0gTGludXggdmVyc2lvbiAyLjYuMTgteGVuVS1lYzItdjEu\nMiAocm9vdEBkb21VLTEyLTMxLTM5LTA3LTUxLTgyKSAoZ2NjIHZlcnNpb24g\nNC4xLjIgMjAwNzA2MjYgKFJlZCBIYXQgNC4xLjItMTMpKSAjMiBTTVAgV2Vk\nIEF1ZyAxOSAwOTowNDozOCBFRFQgMjAwOQ==\n")
      end

      def self.dns_name_for(ip_address)
        "ec2-#{ip_address.gsub('.','-')}.compute-1.amazonaws.com"
      end

      def self.private_dns_name_for(ip_address)
        "ip-#{ip_address.gsub('.','-')}.ec2.internal"
      end

      def self.image
        path = []
        (rand(3) + 2).times do
          path << Fog::Mock.random_letters(rand(9) + 8)
        end
        {
          "imageOwnerId"   => Fog::Mock.random_letters(rand(5) + 4),
          "blockDeviceMapping" => [],
          "productCodes"   => [],
          "kernelId"       => kernel_id,
          "ramdiskId"      => ramdisk_id,
          "imageState"     => "available",
          "imageId"        => image_id,
          "architecture"   => "i386",
          "isPublic"       => true,
          "imageLocation"  => path.join('/'),
          "imageType"      => "machine",
          "rootDeviceType" => ["ebs","instance-store"][rand(2)],
          "rootDeviceName" => "/dev/sda1"
        }
      end

      def self.image_id
        "ami-#{Fog::Mock.random_hex(8)}"
      end

      def self.key_fingerprint
        fingerprint = []
        20.times do
          fingerprint << Fog::Mock.random_hex(2)
        end
        fingerprint.join(':')
      end

      def self.instance_id
        "i-#{Fog::Mock.random_hex(8)}"
      end

      def self.ip_address
        Fog::Mock.random_ip
      end

      def self.private_ip_address
        ip_address.gsub(/^\d{1,3}\./,"10.")
      end

      def self.kernel_id
        "aki-#{Fog::Mock.random_hex(8)}"
      end

      def self.key_material
        OpenSSL::PKey::RSA.generate(1024).to_s
      end

      def self.owner_id
        Fog::Mock.random_numbers(12)
      end

      def self.ramdisk_id
        "ari-#{Fog::Mock.random_hex(8)}"
      end

      def self.request_id
        request_id = []
        request_id << Fog::Mock.random_hex(8)
        3.times do
          request_id << Fog::Mock.random_hex(4)
        end
        request_id << Fog::Mock.random_hex(12)
        request_id.join('-')
      end

      class << self
        alias_method :reserved_instances_id, :request_id
        alias_method :reserved_instances_offering_id, :request_id
        alias_method :sqs_message_id, :request_id
        alias_method :sqs_sender_id, :request_id
      end

      def self.reservation_id
        "r-#{Fog::Mock.random_hex(8)}"
      end

      def self.snapshot_id
        "snap-#{Fog::Mock.random_hex(8)}"
      end

      def self.volume_id
        "vol-#{Fog::Mock.random_hex(8)}"
      end

      def self.security_group_id
        "sg-#{Fog::Mock.random_hex(8)}"
      end

      def self.network_acl_id
        "acl-#{Fog::Mock.random_hex(8)}"
      end
      def self.network_acl_association_id
        "aclassoc-#{Fog::Mock.random_hex(8)}"
      end
      def self.network_interface_id
        "eni-#{Fog::Mock.random_hex(8)}"
      end
      def self.internet_gateway_id
        "igw-#{Fog::Mock.random_hex(8)}"
      end
      def self.dhcp_options_id
        "dopt-#{Fog::Mock.random_hex(8)}"
      end
      def self.vpc_id
        "vpc-#{Fog::Mock.random_hex(8)}"
      end
      def self.subnet_id
        "subnet-#{Fog::Mock.random_hex(8)}"
      end
      def self.zone_id
        "zone-#{Fog::Mock.random_hex(8)}"
      end
      def self.route_table_id
        "rtb-#{Fog::Mock.random_hex(8)}"
      end
      def self.change_id
        Fog::Mock.random_letters_and_numbers(14)
      end
      def self.nameservers
        [
          'ns-2048.awsdns-64.com',
          'ns-2049.awsdns-65.net',
          'ns-2050.awsdns-66.org',
          'ns-2051.awsdns-67.co.uk'
        ]
      end

      def self.key_id(length=21)
        #Probably close enough
        Fog::Mock.random_selection('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',length)
      end

      def self.rds_address(db_name,region)
        "#{db_name}.#{Fog::Mock.random_letters(rand(12) + 4)}.#{region}.rds.amazonaws.com"
      end

      def self.spot_instance_request_id
        "sir-#{Fog::Mock.random_letters_and_numbers(8)}"
      end

      def self.data_pipeline_id
        "df-#{Fog::Mock.random_letters_and_numbers(19).capitalize}"
      end

      def self.spot_product_descriptions
        [
          'Linux/UNIX',
          'Windows',
          'SUSE Linux'
        ]
      end

      def self.default_vpc_for(region)
        @default_vpcs ||= {}
        @default_vpcs[region] ||= vpc_id
      end
    end
  end
end
