module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/get_account_summary'

        # Retrieve account level information about account entity usage and IAM quotas
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Summary'<~Hash>:
        #       * 'AccessKeysPerUserQuota'<~Integer> - Maximum number of access keys that can be created per user
        #       * 'AccountMFAEnabled'<~Integer> - 1 if the root account has an MFA device assigned to it, 0 otherwise
        #       * 'AssumeRolePolicySizeQuota'<~Integer> - Maximum allowed size for assume role policy documents (in kilobytes)
        #       * 'GroupPolicySizeQuota'<~Integer> - Maximum allowed size for Group policy documents (in kilobytes)
        #       * 'Groups'<~Integer> - Number of Groups for the AWS account
        #       * 'GroupsPerUserQuota'<~Integer> - Maximum number of groups a user can belong to
        #       * 'GroupsQuota'<~Integer> - Maximum groups allowed for the AWS account
        #       * 'InstanceProfiles'<~Integer> - Number of instance profiles for the AWS account
        #       * 'InstanceProfilesQuota'<~Integer> - Maximum instance profiles allowed for the AWS account
        #       * 'MFADevices'<~Integer> - Number of MFA devices, either assigned or unassigned
        #       * 'MFADevicesInUse'<~Integer> - Number of MFA devices that have been assigned to an IAM user or to the root account
        #       * 'Providers'<~Integer> -
        #       * 'RolePolicySizeQuota'<~Integer> - Maximum allowed size for role policy documents (in kilobytes)
        #       * 'Roles'<~Integer> - Number of roles for the AWS account
        #       * 'RolesQuota'<~Integer> - Maximum roles allowed for the AWS account
        #       * 'ServerCertificates'<~Integer> - Number of server certificates for the AWS account
        #       * 'ServerCertificatesQuota'<~Integer> - Maximum server certificates allowed for the AWS account
        #       * 'SigningCertificatesPerUserQuota'<~Integer> - Maximum number of X509 certificates allowed for a user
        #       * 'UserPolicySizeQuota'<~Integer> - Maximum allowed size for user policy documents (in kilobytes)
        #       * 'Users'<~Integer> - Number of users for the AWS account
        #       * 'UsersQuota'<~Integer> - Maximum users allowed for the AWS account
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateAccessKey.html
        #
        def get_account_summary
          request(
            'Action'    => 'GetAccountSummary',
            :parser     => Fog::Parsers::AWS::IAM::GetAccountSummary.new
            )
        end
      end

      class Mock
        def get_account_summary
          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = {
              'Summary' => {
                'AccessKeysPerUserQuota' => 2,
                'AccountMFAEnabled' => 0,
                'GroupPolicySizeQuota' => 10240,
                'Groups' => 31,
                'GroupsPerUserQuota' => 10,
                'GroupsQuota' => 50,
                'MFADevices' => 20,
                'MFADevicesInUse' => 10,
                'ServerCertificates' => 5,
                'ServerCertificatesQuota' => 10,
                'SigningCertificatesPerUserQuota' => 2,
                'UserPolicySizeQuota' => 10240,
                'Users' => 35,
                'UsersQuota' => 150,
              },
              'RequestId' => Fog::AWS::Mock.request_id
            }
          end
        end
      end
    end
  end
end
