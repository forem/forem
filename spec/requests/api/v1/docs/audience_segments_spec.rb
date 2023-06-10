require "rails_helper"
require "swagger_helper"

def id_schema
  {
    type: :integer,
    format: :int32,
    minimum: 1
  }
end

# rubocop:disable RSpec/VariableName
# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::AudienceSegments" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin_api_secret) { create(:api_secret) }
  let(:regular_api_secret) { create(:api_secret) }
  let(:segment) { AudienceSegment.create!(type_of: "manual") }
  let(:automatic_segment) { AudienceSegment.create!(type_of: "trusted") }
  let(:users) { create_list(:user, 3) }

  before do
    admin_api_secret.user.add_role(:admin)
  end

  path "/api/segments" do
    describe "GET /segments" do
      get "Manually managed audience segments" do
        tags "segments"
        description "This endpoint allows the client to retrieve a list of audience segments.

An audience segment is a group of users that can be targeted by a Billboard. This API only permits managing segments you create and maintain yourself.

The endpoint supports pagination, and each page will contain `30` segments by default."
        operationId "getSegments"
        produces "application/json"
        consumes "application/json"

        parameter "$ref": "#/components/parameters/perPageParam30to1000"

        response "200", "A List of manually managed audience segments" do
          let(:"api-key") { admin_api_secret.secret }
          let(:second_segment) { AudienceSegment.create!(type_of: "manual") }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/Segment" }

          before do
            segment.users << users
            second_segment.users << create(:user)
          end

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }

          add_examples

          run_test!
        end
      end
    end

    describe "POST /segments" do
      post "Create a manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to create a new audience segment.\n\nAn audience segment is a group of users that can be targeted by a Billboard. This API only permits managing segments you create and maintain yourself."
        operationId "createSegment"
        produces "application/json"
        consumes "application/json"

        response "201", "A manually managed audience segment" do
          let(:"api-key") { admin_api_secret.secret }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }

          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/segments/{id}" do
    describe "GET /segments/:id" do
      get "A manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to retrieve a single manually-managed audience segment specified by ID."
        operationId "getSegment"
        produces "application/json"
        consumes "application/json"

        parameter name: :id, in: :path, required: true, schema: id_schema

        response "200", "The audience segment" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/Segment" }

          before do
            segment.users << users
          end

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "404", "Audience Segment Not Found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { automatic_segment.id }

          add_examples

          run_test!
        end
      end
    end

    describe "DELETE /segments/:id" do
      delete "Delete a manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to delete an audience segment specified by ID.\n\nAudience segments cannot be deleted if there are still any Billboards using them."
        operationId "deleteSegment"
        produces "application/json"
        consumes "application/json"

        parameter name: :id, in: :path, required: true, schema: id_schema

        response "200", "The deleted audience segment" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "404", "Audience Segment Not Found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { automatic_segment.id }

          add_examples

          run_test!
        end

        response "409", "Audience segment could not be deleted" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:billboard) { create(:display_ad, published: true, approved: true) }

          before do
            billboard.update!(audience_segment: segment)
          end

          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /segments/:id/users" do
    path "/api/segments/{id}/users" do
      get "Users in a manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to retrieve a list of the users in an audience segment specified by ID. The endpoint supports pagination, and each page will contain `30` users by default."
        operationId "getUsersInSegment"
        produces "application/json"
        consumes "application/json"

        parameter name: :id, in: :path, required: true, schema: id_schema
        parameter "$ref": "#/components/parameters/perPageParam30to1000"

        response "200", "A List of users in the audience segment" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/User" }

          before do
            segment.users << users
          end

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }
          let(:id) { segment.id }

          add_examples

          run_test!
        end

        response "404", "Audience Segment Not Found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { automatic_segment.id }

          add_examples

          run_test!
        end
      end
    end
  end

  describe "PUT /segments/:id/add_users" do
    path "/api/segments/{id}/add_users" do
      put "Add users to a manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to add users in bulk to an audience segment specified by ID.\n\nSuccesses are users that were included in the segment (even if they were already in it), and failures are users that could not be added to the segment."
        operationId "addUsersToSegment"
        produces "application/json"
        consumes "application/json"

        parameter name: :id, in: :path, required: true, schema: id_schema
        parameter name: :user_ids,
                  in: :body,
                  schema: { "$ref": "#/components/schemas/SegmentUserIds" }

        response "200", "Result of adding the users to the segment." do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "404", "Audience Segment Not Found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { automatic_segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: [] } }

          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { (1..10_100).to_a }

          add_examples

          run_test!
        end
      end
    end
  end

  describe "PUT /segments/:id/remove_users" do
    path "/api/segments/{id}/remove_users" do
      put "Remove users from a manually managed audience segment" do
        tags "segments"
        description "This endpoint allows the client to remove users in bulk from an audience segment specified by ID.\n\nSuccesses are users that were removed; failures are users that weren't a part of the segment."
        operationId "removeUsersFromSegment"
        produces "application/json"
        consumes "application/json"

        parameter name: :id, in: :path, required: true, schema: id_schema
        parameter name: :user_ids,
                  in: :body,
                  schema: { "$ref": "#/components/schemas/SegmentUserIds" }

        before do
          segment.users << users
        end

        response "200", "Result of removing the users to the segment." do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { regular_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "404", "Audience Segment Not Found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { automatic_segment.id }
          let(:user_ids) { { user_ids: users.map(&:id) } }

          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { { user_ids: [] } }

          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { segment.id }
          let(:user_ids) { (1..10_100).to_a }

          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
