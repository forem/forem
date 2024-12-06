module Fog
  module AWS
    class DNS < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :host, :path, :port, :scheme, :version, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :region, :sts_endpoint

      model_path 'fog/aws/models/dns'
      model       :record
      collection  :records
      model       :zone
      collection  :zones

      request_path 'fog/aws/requests/dns'
      request :create_health_check
      request :create_hosted_zone
      request :delete_health_check
      request :get_health_check
      request :get_hosted_zone
      request :delete_hosted_zone
      request :list_health_checks
      request :list_hosted_zones
      request :change_resource_record_sets
      request :list_resource_record_sets
      request :get_change


      class Mock
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :buckets => {},
                :limits => {
                  :duplicate_domains => 5
                },
                :zones => {},
                :changes => {}
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)
          @region             = options[:region]
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset_data
          self.class.data[@region].delete(@aws_access_key_id)
        end

        def signature(params)
          "foo"
        end

        def setup_credentials(options)
          @aws_access_key_id  = options[:aws_access_key_id]
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        # Initialize connection to Route 53 DNS service
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   dns = Fog::AWS::DNS.new(
        #     :aws_access_key_id => your_aws_access_key_id,
        #     :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * dns object with connection to aws.
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.dns'
          @connection_options     = options[:connection_options] || {}
          @host       = options[:host]        || 'route53.amazonaws.com'
          @path       = options[:path]        || '/'
          @persistent = options.fetch(:persistent, true)
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @version    = options[:version]     || '2013-04-01'

          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @hmac       = Fog::HMAC.new('sha1', @aws_secret_access_key)
        end

        def request(params, &block)
          refresh_credentials_if_expired

          params[:headers] ||= {}
          params[:headers]['Date'] = Fog::Time.now.to_date_header
          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params[:headers]['X-Amzn-Authorization'] = "AWS3-HTTPS AWSAccessKeyId=#{@aws_access_key_id},Algorithm=HmacSHA1,Signature=#{signature(params)}"
          params[:path] = "/#{@version}/#{params[:path]}"

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(params, &block)
            end
          else
            _request(params, &block)
          end
        end

        def _request(params, &block)
          @connection.request(params, &block)
        rescue Excon::Errors::HTTPStatusError => error
          match = Fog::AWS::Errors.match_error(error)

          if match.empty?
            raise
          else
            raise case match[:code]
            when 'NoSuchHostedZone', 'NoSuchChange' then
              Fog::AWS::DNS::NotFound.slurp(error, match[:message])
            else
              Fog::AWS::DNS::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
            end
          end
        end

        def signature(params)
          string_to_sign = params[:headers]['Date']
          signed_string = @hmac.sign(string_to_sign)
          Base64.encode64(signed_string).chomp!
        end
      end

      def self.hosted_zone_for_alias_target(dns_name)
        hosted_zones = if dns_name.match(/^dualstack\./)
          elb_dualstack_hosted_zone_mapping
        else
          elb_hosted_zone_mapping
        end

        Hash[hosted_zones.select { |k, _|
          dns_name =~ /\A.+\.#{k}\.elb\.amazonaws\.com\.?\z/
        }].values.last
      end

      def self.elb_hosted_zone_mapping
        @elb_hosted_zone_mapping ||= {
          "ap-northeast-1" => "Z2YN17T5R711GT",
          "ap-southeast-1" => "Z1WI8VXHPB1R38",
          "ap-southeast-2" => "Z2999QAZ9SRTIC",
          "eu-west-1"      => "Z3NF1Z3NOM5OY2",
          "eu-central-1"   => "Z215JYRZR1TBD5",
          "sa-east-1"      => "Z2ES78Y61JGQKS",
          "us-east-1"      => "Z3DZXE0Q79N41H",
          "us-west-1"      => "Z1M58G0W56PQJA",
          "us-west-2"      => "Z33MTJ483KN6FU",
        }
      end

      # See https://docs.aws.amazon.com/general/latest/gr/rande.html#elb_region
      # This needs to be kept in sync manually sadly for now as seemingly this data is not available via an API
      def self.elb_dualstack_hosted_zone_mapping
        @elb_dualstack_hosted_zone_mapping ||= {
          "ap-northeast-1" => "Z14GRHDCWA56QT",
          "ap-northeast-2" => "ZWKZPGTI48KDX",
          "ap-northeast-3" => "Z5LXEXXYW11ES",
          "ap-south-1" => "ZP97RAFLXTNZK",
          "ap-southeast-1" => "Z1LMS91P8CMLE5",
          "ap-southeast-2" => "Z1GM3OXH4ZPM65",
          "ca-central-1" => "ZQSVJUPU6J1EY",
          "eu-central-1" => "Z215JYRZR1TBD5",
          "eu-west-1" => "Z32O12XQLNTSW2",
          "eu-west-2" => "ZHURV8PSTC4K8",
          "eu-west-3" => "Z3Q77PNBQS71R4",
          "us-east-1" => "Z35SXDOTRQ7X7K",
          "us-east-2" => "Z3AADJGX6KTTL2",
          "us-west-1" => "Z368ELLRRE2KJ0",
          "us-west-2" => "Z1H1FL5HABSF5",
          "sa-east-1" => "Z2P70J7HTTTPLU",
        }
      end

      # Returns the xml request for a given changeset
      def self.change_resource_record_sets_data(zone_id, change_batch, version, options = {})
        # AWS methods return zone_ids that looks like '/hostedzone/id'.  Let the caller either use
        # that form or just the actual id (which is what this request needs)
        zone_id = zone_id.sub('/hostedzone/', '')

        optional_tags = ''
        options.each do |option, value|
          case option
          when :comment
            optional_tags += "<Comment>#{value}</Comment>"
          end
        end

        #build XML
        if change_batch.count > 0

          changes = "<ChangeBatch>#{optional_tags}<Changes>"

          change_batch.each do |change_item|
            action_tag = %Q{<Action>#{change_item[:action]}</Action>}
            name_tag   = %Q{<Name>#{change_item[:name]}</Name>}
            type_tag   = %Q{<Type>#{change_item[:type]}</Type>}

            # TTL must be omitted if using an alias record
            ttl_tag = ''
            ttl_tag += %Q{<TTL>#{change_item[:ttl]}</TTL>} unless change_item[:alias_target]

            weight_tag = ''
            set_identifier_tag = ''
            region_tag = ''
            if change_item[:set_identifier]
              set_identifier_tag += %Q{<SetIdentifier>#{change_item[:set_identifier]}</SetIdentifier>}
              if change_item[:weight] # Weighted Record
                weight_tag += %Q{<Weight>#{change_item[:weight]}</Weight>}
              elsif change_item[:region] # Latency record
                region_tag += %Q{<Region>#{change_item[:region]}</Region>}
              end
            end

            failover_tag = if change_item[:failover]
                             %Q{<Failover>#{change_item[:failover]}</Failover>}
                           end

            geolocation_tag = if change_item[:geo_location]
                                xml_geo = change_item[:geo_location].map { |k,v| "<#{k}>#{v}</#{k}>" }.join
                                %Q{<GeoLocation>#{xml_geo}</GeoLocation>}
                              end

            resource_records = change_item[:resource_records] || []
            resource_record_tags = ''
            resource_records.each do |record|
              resource_record_tags += %Q{<ResourceRecord><Value>#{record}</Value></ResourceRecord>}
            end

            # ResourceRecords must be omitted if using an alias record
            resource_tag = ''
            resource_tag += %Q{<ResourceRecords>#{resource_record_tags}</ResourceRecords>} if resource_records.any?

            alias_target_tag = ''
            if change_item[:alias_target]
              # Accept either underscore or camel case for hash keys.
              dns_name = change_item[:alias_target][:dns_name] || change_item[:alias_target][:DNSName]
              hosted_zone_id = change_item[:alias_target][:hosted_zone_id] || change_item[:alias_target][:HostedZoneId] || AWS.hosted_zone_for_alias_target(dns_name)
              evaluate_target_health = change_item[:alias_target][:evaluate_target_health] || change_item[:alias_target][:EvaluateTargetHealth] || false
              evaluate_target_health_xml = !evaluate_target_health.nil? ? %Q{<EvaluateTargetHealth>#{evaluate_target_health}</EvaluateTargetHealth>} : ''
              alias_target_tag += %Q{<AliasTarget><HostedZoneId>#{hosted_zone_id}</HostedZoneId><DNSName>#{dns_name}</DNSName>#{evaluate_target_health_xml}</AliasTarget>}
            end

            health_check_id_tag = if change_item[:health_check_id]
                                    %Q{<HealthCheckId>#{change_item[:health_check_id]}</HealthCheckId>}
                                  end

            change_tags = %Q{<Change>#{action_tag}<ResourceRecordSet>#{name_tag}#{type_tag}#{set_identifier_tag}#{weight_tag}#{region_tag}#{failover_tag}#{geolocation_tag}#{ttl_tag}#{resource_tag}#{alias_target_tag}#{health_check_id_tag}</ResourceRecordSet></Change>}
            changes += change_tags
          end

          changes += '</Changes></ChangeBatch>'
        end

        %Q{<?xml version="1.0" encoding="UTF-8"?><ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/#{version}/">#{changes}</ChangeResourceRecordSetsRequest>}
      end
    end
  end

  # @deprecated
  module DNS
    # @deprecated
    class AWS < Fog::AWS::DNS
      # @deprecated
      # @overrides Fog::Service.new (from the fog-core gem)
      def self.new(*)
        Fog::Logger.deprecation 'Fog::DNS::AWS is deprecated, please use Fog::AWS::DNS.'
        super
      end
    end
  end
end
