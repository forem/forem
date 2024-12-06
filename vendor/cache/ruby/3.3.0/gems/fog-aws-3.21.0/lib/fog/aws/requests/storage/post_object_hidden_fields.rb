module Fog
  module AWS
    class Storage
      module PostObjectHiddenFields
        # Get a hash of hidden fields for form uploading to S3, in the form {:field_name => :field_value}
        # Form should look like: <form action="http://#{bucket_name}.s3.amazonaws.com/" method="post" enctype="multipart/form-data">
        # These hidden fields should then appear, followed by a field named 'file' which is either a textarea or file input.
        #
        # @param options Hash:
        # @option options acl [String] access control list, in ['private', 'public-read', 'public-read-write', 'authenticated-read', 'bucket-owner-read', 'bucket-owner-full-control']
        # @option options Cache-Control [String] same as REST header
        # @option options Content-Type [String] same as REST header
        # @option options Content-Disposition [String] same as REST header
        # @option options Content-Encoding [String] same as REST header
        # @option options Expires same as REST header
        # @option options key key for object, set to '${filename}' to use filename provided by user
        # @option options policy security policy for upload
        # @option options success_action_redirect url to redirct to upon success
        # @option options success_action_status status code to return on success, in [200, 201, 204]
        # @option options x-amz-security token devpay security token
        # @option options x-amz-meta... meta data tags
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/dev/HTTPPOSTForms.html
        #
        def post_object_hidden_fields(options = {})
          options = options.dup
          if policy = options['policy']
            date = Fog::Time.now
            credential = "#{@aws_access_key_id}/#{@signer.credential_scope(date)}"
            extra_conditions = [
              {'x-amz-date' => date.to_iso8601_basic},
              {'x-amz-credential' => credential},
              {'x-amz-algorithm' => Fog::AWS::SignatureV4::ALGORITHM}
            ]

            extra_conditions << {'x-amz-security-token' => @aws_session_token } if @aws_session_token

            policy_with_auth_fields = policy.merge('conditions' => policy['conditions'] + extra_conditions)

            options['policy'] = Base64.encode64(Fog::JSON.encode(policy_with_auth_fields)).gsub("\n", "")
            options['X-Amz-Credential'] = credential
            options['X-Amz-Date'] = date.to_iso8601_basic
            options['X-Amz-Algorithm'] = Fog::AWS::SignatureV4::ALGORITHM
            if @aws_session_token
              options['X-Amz-Security-Token'] = @aws_session_token
            end
            options['X-Amz-Signature'] = @signer.derived_hmac(date).sign(options['policy']).unpack('H*').first
          end
          options
        end
      end
      class Real
        include PostObjectHiddenFields
      end
      class Mock
        include PostObjectHiddenFields
      end
    end
  end
end
