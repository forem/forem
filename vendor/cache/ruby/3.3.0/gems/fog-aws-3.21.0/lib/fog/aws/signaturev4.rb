# See http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html

module Fog
  module AWS
    class SignatureV4
      ALGORITHM = 'AWS4-HMAC-SHA256'

      def initialize(aws_access_key_id, secret_key, region, service)
        @region = region
        @service = service
        @aws_access_key_id  = aws_access_key_id
        @hmac = Fog::HMAC.new('sha256', 'AWS4' + secret_key)
      end

      def signature_parameters(params, date, body_sha = nil)
        params = params.dup.merge(:query => params[:query].merge(
          'X-Amz-Algorithm' => ALGORITHM,
          'X-Amz-Credential' => "#{@aws_access_key_id}/#{credential_scope(date)}",
          'X-Amz-SignedHeaders' => signed_headers(params[:headers])
        ))
        signature_components(params, date, body_sha)
      end

      def signature_header(params, date, body_sha = nil)
        components_to_header(signature_components(params, date, body_sha))
      end

      def sign(params, date) #legacy method name
        signature_header(params, date)
      end

      def components_to_header components
        "#{components['X-Amz-Algorithm']} Credential=#{components['X-Amz-Credential']}, SignedHeaders=#{components['X-Amz-SignedHeaders']}, Signature=#{components['X-Amz-Signature']}" 
      end

      def signature_components(params, date, body_sha)
        canonical_request = <<-DATA
#{params[:method].to_s.upcase}
#{canonical_path(params[:path])}
#{canonical_query_string(params[:query])}
#{canonical_headers(params[:headers])}
#{signed_headers(params[:headers])}
#{body_sha || OpenSSL::Digest::SHA256.hexdigest(params[:body] || '')}
DATA
        canonical_request.chop!

        string_to_sign = <<-DATA
#{ALGORITHM}
#{date.to_iso8601_basic}
#{credential_scope(date)}
#{OpenSSL::Digest::SHA256.hexdigest(canonical_request)}
DATA

        string_to_sign.chop!

        signature = derived_hmac(date).sign(string_to_sign)

        {
          'X-Amz-Algorithm' => ALGORITHM,
          'X-Amz-Credential' => "#{@aws_access_key_id}/#{credential_scope(date)}",
          'X-Amz-SignedHeaders' => signed_headers(params[:headers]),
          'X-Amz-Signature' => signature.unpack('H*').first
        }
      end

      def derived_hmac(date)
        kDate = @hmac.sign(date.utc.strftime('%Y%m%d'))
        kRegion = Fog::HMAC.new('sha256', kDate).sign(@region)
        kService = Fog::HMAC.new('sha256', kRegion).sign(@service)
        kSigning = Fog::HMAC.new('sha256', kService).sign('aws4_request')
        Fog::HMAC.new('sha256', kSigning)
      end


      def credential_scope(date)
        "#{date.utc.strftime('%Y%m%d')}/#{@region}/#{@service}/aws4_request"
      end

      protected

      def canonical_path(path)
        unless @service == 's3' #S3 implements signature v4 different - paths are not canonialized
          #leading and trailing repeated slashes are collapsed, but not ones that appear elsewhere
          path = path.gsub(%r{\A/+},'/').gsub(%r{/+\z},'/')
          components = path.split('/',-1)
          path = components.inject([]) do |acc, component|
            case component
            when '.'   #canonicalize by removing .
            when '..' then acc.pop#canonicalize by reducing ..
            else
              acc << component
            end
            acc
          end.join('/')
        end
        path.empty? ? '/' : path
      end

      def canonical_query_string(query)
        canonical_query_string = []
        for key in (query || {}).keys.sort_by {|k| k.to_s}
          component = "#{Fog::AWS.escape(key.to_s)}=#{Fog::AWS.escape(query[key].to_s)}"
          canonical_query_string << component
        end
        canonical_query_string.join("&")
      end

      def canonical_headers(headers)
        canonical_headers = ''

        for key in headers.keys.sort_by {|k| k.to_s.downcase}
          canonical_headers << "#{key.to_s.downcase}:#{headers[key].to_s.strip}\n"
        end
        canonical_headers
      end

      def signed_headers(headers)
        headers.keys.map {|key| key.to_s.downcase}.sort.join(';')
      end
    end
  end
end
