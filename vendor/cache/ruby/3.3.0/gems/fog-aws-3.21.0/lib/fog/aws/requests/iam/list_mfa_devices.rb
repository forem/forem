module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_mfa_devices'

        # List MFA Devices
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'Marker'<~String> - used to paginate subsequent requests
        #   * 'MaxItems'<~Integer> - limit results to this number per page
        #   * 'UserName'<~String> - optional: username to lookup mfa devices for, defaults to current user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'MFADevices'<~Array> - Matching MFA devices
        #       * mfa_device<~Hash>:
        #         * EnableDate - The date when the MFA device was enabled for the user
        #         * SerialNumber<~String> - The serial number that uniquely identifies the MFA device
        #         * UserName<~String> - The user with whom the MFA device is associated
        #     * 'IsTruncated<~Boolean> - Whether or not results were truncated
        #     * 'Marker'<~String> - appears when IsTruncated is true as the next marker to use
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_ListMFADevices.html
        #
        def list_mfa_devices(options = {})
          request({
            'Action'  => 'ListMFADevices',
            :parser   => Fog::Parsers::AWS::IAM::ListMFADevices.new
          }.merge!(options))
        end
      end

      class Mock
        def list_mfa_devices(options = {})
          #FIXME: Doesn't observe options
          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = { 'MFADevices' => data[:devices].map do |device|
                                            { 'EnableDate'   => device[:enable_date],
                                              'SerialNumber' => device[:serial_number],
                                              'UserName'     => device[:user_name] }
                                          end,
                              'IsTruncated' => false,
                              'RequestId' => Fog::AWS::Mock.request_id }
          end
        end
      end
    end
  end
end
