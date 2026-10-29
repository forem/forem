require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

describe "GET /tags" do
  before { create_list(:tag, 3) }

  path "/api/tags" do
    get "Tags" do
      tags "tags"
      security []
      description "Retrieve a list of tags used on the platform, ordered by popularity.

### Integration Tips:
- Bypasses authentication (can be accessed publicly).
- Ordered by overall popularity/usage metrics on the platform.
- Useful for autocomplete inputs in article editors and tag selection screens in settings.
- Supports global navigation and explore lists.
- Pass `name` to look up one tag by its exact name, for example to find its ID.
  The lookup also finds tags that are not supported.

It supports pagination, each page will contain 10 tags by default."
      operationId "getTags"
      produces "application/json"
      parameter "$ref": "#/components/parameters/pageParam"
      parameter "$ref": "#/components/parameters/perPageParam10to1000"
      parameter name: :name, in: :query, required: false,
                description: "Return only the tag with this exact name (case-insensitive).  " \
                             "The result is an empty list if there is no such tag.",
                schema: { type: :string },
                example: "javascript"

      response "200", "A List of all tags" do
        schema  type: :array,
                items: { "$ref": "#/components/schemas/Tag" }
        add_examples

        run_test!
      end
    end
  end

  path "/api/tags" do
    post "Create a tag" do
      tags "tags"
      description(<<~DESCRIBE.strip)
        Create a tag before it appears on an article.

        Requires an API key for an admin, super admin, or single resource admin on Tag.  Each successful creation writes an admin API audit entry.
        Accepts a required alphanumeric name of at most 30 characters, plus the optional fields accepted by tag update.
        Returns the same fields as tag update.  A duplicate name returns 422 with an error and the existing tag's id, without changing that tag.
      DESCRIBE
      operationId "createTag"
      produces "application/json"
      consumes "application/json"

      parameter name: :tag_params, in: :body, required: true,
                description: "Tag name and optional display fields",
                schema: {
                  type: :object,
                  required: ["name"],
                  properties: {
                    name: { type: :string, maxLength: 30, example: "javascript" },
                    pretty_name: { type: :string, nullable: true },
                    short_summary: { type: :string, nullable: true },
                    wiki_body_markdown: { type: :string, nullable: true },
                    supported: { type: :boolean },
                    bg_color_hex: { type: :string, nullable: true, example: "#1E90FF" },
                    text_color_hex: { type: :string, nullable: true, example: "#FFFFFF" },
                    context_note_instructions: { type: :string, nullable: true }
                  }
                }

      let(:Accept) { "application/vnd.forem.api-v1+json" }
      let(:api_secret) { create(:api_secret, user: create(:user, :admin)) }
      let(:tag_params) { { name: "javascript", pretty_name: "JavaScript", supported: true } }

      response "201", "The created tag" do
        let(:"api-key") { api_secret.secret }
        schema "$ref": "#/components/schemas/ExtendedTag"
        add_examples

        run_test!
      end

      response "401", "Unauthorized" do
        let(:"api-key") { "invalid" }
        add_examples

        run_test!
      end

      response "422", "Invalid tag or duplicate name" do
        let(:"api-key") { api_secret.secret }
        let!(:existing_tag) { create(:tag, name: "javascript") }
        schema type: :object,
               required: %w[error status],
               properties: {
                 error: { type: :string },
                 status: { type: :integer, example: 422 },
                 id: { type: :integer, description: "Existing tag id, present only for duplicate names" }
               }
        add_examples

        run_test! do |response|
          expect(response.parsed_body["id"]).to eq(existing_tag.id)
        end
      end
    end
  end

  path "/api/tags/supported" do
    get "Supported tags" do
      tags "tags"
      security []
      description "Retrieve every tag supported on the platform (or current subforem), ordered by popularity.

### Integration Tips:
- Bypasses authentication (can be accessed publicly).
- Not paginated: returns the complete list of supported tags in a single response.
- Edge cached; changes to a tag's supported status are purged from the cache automatically."
      operationId "getSupportedTags"
      produces "application/json"

      response "200", "A List of all supported tags" do
        schema  type: :array,
                items: { "$ref": "#/components/schemas/Tag" }
        add_examples

        run_test!
      end
    end
  end

  path "/api/tags/{id}" do
    put "Update a tag" do
      tags "tags"
      description(<<~DESCRIBE.strip)
        Update a tag's display details and wiki by ID.

        Requires an API key that belongs to a super admin, an admin, or a user with the `single_resource_admin` role on Tag. Each update is written to the admin API audit log.

        ### Body Parameter Guidelines:
        - All fields are optional; only the fields you send are changed.
        - **pretty_name**: Display name for the tag, e.g. `JavaScript` for `javascript`.
        - **short_summary**: Short description shown with the tag.
        - **wiki_body_markdown**: Markdown body of the tag's wiki.
        - **supported**: Whether the tag is supported on the platform.
        - **bg_color_hex** / **text_color_hex**: Tag colors as hexadecimal values, e.g. `#1E90FF`.
        - **context_note_instructions**: Instructions shown to people who add a context note to a post with this tag.

        The tag's `name` cannot be changed. The response has the fields of an item in `GET /api/tags` plus every editable field, so callers can confirm the edit.
      DESCRIBE
      operationId "updateTag"
      produces "application/json"
      consumes "application/json"

      parameter name: :id, in: :path, required: true,
                description: "The ID of the tag to update.",
                schema: { type: :integer, format: :int64, minimum: 1 },
                example: 1
      parameter name: :tag_params, in: :body, required: true,
                description: "Tag fields to update",
                schema: {
                  type: :object,
                  properties: {
                    pretty_name: { type: :string, nullable: true },
                    short_summary: { type: :string, nullable: true },
                    wiki_body_markdown: { type: :string, nullable: true },
                    supported: { type: :boolean },
                    bg_color_hex: { type: :string, nullable: true, example: "#1E90FF" },
                    text_color_hex: { type: :string, nullable: true, example: "#FFFFFF" },
                    context_note_instructions: { type: :string, nullable: true }
                  }
                }

      let(:Accept) { "application/vnd.forem.api-v1+json" }
      let(:api_secret) { create(:api_secret, user: create(:user, :super_admin)) }
      let(:tag) { create(:tag) }
      let(:id) { tag.id }
      let(:tag_params) { { pretty_name: "JavaScript", short_summary: "All about JS", supported: true } }

      response "200", "The updated tag" do
        let(:"api-key") { api_secret.secret }
        schema "$ref": "#/components/schemas/ExtendedTag"
        add_examples

        run_test!
      end

      response "401", "Unauthorized" do
        let(:"api-key") { "invalid" }
        add_examples

        run_test!
      end

      response "404", "Tag not found" do
        let(:"api-key") { api_secret.secret }
        let(:id) { 0 }
        add_examples

        run_test!
      end

      response "422", "Unprocessable entity" do
        let(:"api-key") { api_secret.secret }
        let(:tag_params) { { bg_color_hex: "not-a-color" } }
        add_examples

        run_test!
      end
    end
  end
  path "/api/tags/{id}/moderators" do
    moderator_params_schema = {
      type: :object,
      properties: {
        user_id: { type: :integer, format: :int64, example: 1 },
        username: { type: :string, example: "ben" }
      }
    }
    moderator_schema = {
      type: :object,
      required: %w[tag_id tag_name user_id username],
      properties: {
        tag_id: { type: :integer, format: :int64 },
        tag_name: { type: :string },
        user_id: { type: :integer, format: :int64 },
        username: { type: :string }
      }
    }

    let(:Accept) { "application/vnd.forem.api-v1+json" }
    let(:api_secret) { create(:api_secret, user: create(:user, :admin)) }
    let(:tag) { create(:tag) }
    let(:id) { tag.id }
    let(:moderator) { create(:user) }
    let(:moderator_params) { { username: moderator.username } }

    post "Add a tag moderator" do
      tags "tags"
      description(<<~DESCRIBE.strip)
        Make a user a moderator of a tag, with the same effects as adding them on the admin tag page: the tag moderator role, the trusted role, tag moderator newsletter emails, a confirmation email, and the tag marked as supported.

        Requires an API key for an admin, super admin, or single resource admin on Tag.  Each successful change writes an admin API audit entry.
        Returns 422 if the user is already a moderator of the tag.
      DESCRIBE
      operationId "addTagModerator"
      produces "application/json"
      consumes "application/json"

      parameter name: :id, in: :path, required: true,
                description: "The ID of the tag.",
                schema: { type: :integer, format: :int64, minimum: 1 },
                example: 1
      parameter name: :moderator_params, in: :body, required: true,
                description: "The user, by `user_id` or `username`.  `user_id` is used if both are sent.",
                schema: moderator_params_schema

      response "201", "The moderator was added" do
        let(:"api-key") { api_secret.secret }
        schema moderator_schema
        add_examples

        run_test!
      end

      response "401", "Unauthorized" do
        let(:"api-key") { "invalid" }
        add_examples

        run_test!
      end

      response "404", "Tag or user not found" do
        let(:"api-key") { api_secret.secret }
        let(:moderator_params) { { username: "nobody-here" } }
        add_examples

        run_test!
      end

      response "422", "The user is already a moderator of the tag" do
        let(:"api-key") { api_secret.secret }
        let(:moderator) { create(:user).tap { |user| user.add_role(:tag_moderator, tag) } }
        add_examples

        run_test!
      end
    end

    delete "Remove a tag moderator" do
      tags "tags"
      description(<<~DESCRIBE.strip)
        Remove a user's moderator role on a tag, with the same effects as removing them on the admin tag page.

        Requires an API key for an admin, super admin, or single resource admin on Tag.  Each successful change writes an admin API audit entry.
        Returns 422 if the user is not a moderator of the tag.
      DESCRIBE
      operationId "removeTagModerator"
      produces "application/json"
      consumes "application/json"

      parameter name: :id, in: :path, required: true,
                description: "The ID of the tag.",
                schema: { type: :integer, format: :int64, minimum: 1 },
                example: 1
      parameter name: :moderator_params, in: :body, required: true,
                description: "The user, by `user_id` or `username`.  `user_id` is used if both are sent.",
                schema: moderator_params_schema

      response "200", "The moderator was removed" do
        let(:"api-key") { api_secret.secret }
        let(:moderator) { create(:user).tap { |user| user.add_role(:tag_moderator, tag) } }
        schema moderator_schema
        add_examples

        run_test!
      end

      response "401", "Unauthorized" do
        let(:"api-key") { "invalid" }
        add_examples

        run_test!
      end

      response "404", "Tag or user not found" do
        let(:"api-key") { api_secret.secret }
        let(:moderator_params) { { username: "nobody-here" } }
        add_examples

        run_test!
      end

      response "422", "The user is not a moderator of the tag" do
        let(:"api-key") { api_secret.secret }
        add_examples

        run_test!
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
