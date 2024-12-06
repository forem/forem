require 'fog/aws/models/iam/group'
require 'fog/aws/iam/paged_collection'

module Fog
  module AWS
    class IAM
      class Groups < Fog::AWS::IAM::PagedCollection

        attribute :username

        model Fog::AWS::IAM::Group

        def all(options = {})
          data, records = if self.username
                            response = service.list_groups_for_user(self.username, options)
                            [response.body, response.body['GroupsForUser']]
                          else
                            response = service.list_groups(options)
                            [response.body, response.body['Groups']]
                          end

          merge_attributes(data)
          load(records)
        end

        def get(identity)
          data = service.get_group(identity)

          group = data.body['Group']
          users = data.body['Users'].map { |u| service.users.new(u) }

          new(group.merge(:users => users))
        rescue Fog::AWS::IAM::NotFound
          nil
        end
      end
    end
  end
end
