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
- Useful for autocomplete inputs in article editors, tag selection screens in settings, or rendering global navigation/explore lists.

It supports pagination, each page will contain 10 tags by default."
      operationId "getTags"
      produces "application/json"
      parameter "$ref": "#/components/parameters/pageParam"
      parameter "$ref": "#/components/parameters/perPageParam10to1000"

      response "200", "A List of all tags" do
        schema  type: :array,
                items: { "$ref": "#/components/schemas/Tag" }
        add_examples

        run_test!
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
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
