module Fog
  module AWS
    class Storage
      class Real
        # Change website configuration for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to modify
        # @param options [Hash]
        # @option options RedirectAllRequestsTo [String] Host name to redirect all requests to - if this is set, other options are ignored
        # @option options IndexDocument [String] suffix to append to requests for the bucket
        # @option options ErrorDocument [String] key to use for 4XX class errors
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html

        def put_bucket_website(bucket_name, options, options_to_be_deprecated = {})
          options ||= {}

          # Method used to be called with the suffix as the second parameter. Warn user that this is not the case any more and move on
          if options.is_a?(String)
            Fog::Logger.deprecation("put_bucket_website with #{options.class} param is deprecated, use put_bucket_website('#{bucket_name}', :IndexDocument => '#{options}') instead [light_black](#{caller.first})[/]")
            options = { :IndexDocument => options }
          end

          # Parameter renamed from "key" to "ErrorDocument"
          if options_to_be_deprecated[:key]
            Fog::Logger.deprecation("put_bucket_website with three parameters is deprecated, use put_bucket_website('#{bucket_name}', :ErrorDocument => '#{options_to_be_deprecated[:key]}') instead [light_black](#{caller.first})[/]")
            options[:ErrorDocument] = options_to_be_deprecated[:key]
          end

          options.merge!(options_to_be_deprecated) { |key, o1, o2| o1 }

          data = "<WebsiteConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"

          if options[:RedirectAllRequestsTo]
            # Redirect precludes all other options
            data << <<-DATA
                      <RedirectAllRequestsTo>
                        <HostName>#{options[:RedirectAllRequestsTo]}</HostName>
                      </RedirectAllRequestsTo>
                    DATA
          else

            if options[:IndexDocument]
            data << <<-DATA
                      <IndexDocument>
                        <Suffix>#{options[:IndexDocument]}</Suffix>
                      </IndexDocument>
                    DATA
            end

            if options[:ErrorDocument]
              data << <<-DATA
                        <ErrorDocument>
                          <Key>#{options[:ErrorDocument]}</Key>
                        </ErrorDocument>
                      DATA
            end
          end

          data << '</WebsiteConfiguration>'
          request({
            :body     => data,
            :expects  => 200,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'website' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def put_bucket_website(bucket_name, suffix, options = {})
          response = Excon::Response.new
          if self.data[:buckets][bucket_name]
            response.status = 200
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end

          response
        end
      end
    end
  end
end
