require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you"re using the rswag-api to serve API descriptions, you"ll need
  # to ensure that it"s configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the "rswag:specs:swaggerize" rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe "...", swagger_doc: "v2/swagger.json"
  config.swagger_docs = {
    "v1/api_v1.json" => {
      openapi: "3.0.3",
      info: {
        title: "Forem API V1",
        version: "1.0.0",
        description: "Access Forem articles, users and other resources via API.
        For a real-world example of Forem in action, check out [DEV](https://www.dev.to).
        All endpoints can be accessed with the 'api-key' header and a accept header, but
        some of them are accessible publicly without authentication.

        Dates and date times, unless otherwise specified, must be in
        the [RFC 3339](https://tools.ietf.org/html/rfc3339) format."
      },
      paths: {},
      servers: [
        {
          url: "https://dev.to/api",
          description: "Production server"
        },
      ],
      security: [{ "api-key": [] }],
      components: {
        securitySchemes: {
          "api-key": {
            type: :apiKey,
            name: "api-key",
            in: :header,
            description: "API Key authentication.

Authentication for some endpoints, like write operations on the
Articles API require a DEV API key.

All authenticated endpoints are CORS disabled, the API key is intended for non-browser scripts.

### Getting an API key

To obtain one, please follow these steps:

  - visit https://dev.to/settings/extensions
  - in the \"DEV API Keys\" section create a new key by adding a
    description and clicking on \"Generate API Key\"

    ![obtain a DEV API Key](https://user-images.githubusercontent.com/37842/172718105-bd93664e-76e0-477d-99c4-265dda0b06c5.png)

  - You'll see the newly generated key in the same view
    ![generated DEV API Key](https://user-images.githubusercontent.com/37842/172718151-e7fe26a0-9937-42e8-96c6-333acdab9e49.png)"
          }
        },
        parameters: {
          pageParam: {
            in: :query,
            name: :page,
            required: false,
            description: "Pagination page",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              default: 1
            }
          },
          perPageParam10to1000: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 1000,
              default: 10
            }
          },
          perPageParam24to1000: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 1000,
              default: 24
            }
          },
          perPageParam30to1000: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 1000,
              default: 30
            }
          },
          perPageParam30to100: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 100,
              default: 30
            }
          },
          perPageParam80to1000: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 1000,
              default: 80
            }
          },
          listingCategoryParam: {
            name: :category,
            in: :query,
            description: "Using this parameter will return listings belonging to the
              requested category.",
            schema: {
              type: :string
            },
            example: "cfp"
          }
        },
        schemas: {
          ArticleFlareTag: {
            description: "Flare tag of the article",
            type: "object",
            properties: {
              name: { type: :string },
              bg_color_hex: { description: "Background color (hexadecimal)", type: :string },
              text_color_hex: { description: "Text color (hexadecimal)", type: :string }
            }
          },
          ArticleIndex: {
            description: "Resprentation of an article or post returned in a list",
            type: :object,
            properties: {
              type_of: { type: :string },
              id: { type: :integer, format: :int32 },
              title: { type: :string },
              description: { type: :string },
              cover_image: { type: :string, format: :url, nullable: true },
              readable_publish_date: { type: :string },
              social_image: { type: :string, format: :url },
              tag_list: { type: :array, items: {
                type: :string
              } },
              tags: { type: :string },
              slug: { type: :string },
              path: { type: :string, format: "path" },
              url: { type: :string, format: :url },
              canonical_url: { type: :string, format: :url },
              positive_reactions_count: { type: :integer, format: :int32 },
              public_reactions_count: { type: :integer, format: :int32 },
              created_at: { type: :string, format: "date-time" },
              edited_at: { type: :string, format: "date-time", nullable: true },
              crossposted_at: { type: :string, format: "date-time", nullable: true },
              published_at: { type: :string, format: "date-time" },
              last_comment_at: { type: :string, format: "date-time" },
              published_timestamp: { description: "Crossposting or published date time", type: :string,
                                     format: "date-time" },
              reading_time_minutes: { description: "Reading time, in minutes", type: :integer, format: :int32 },
              user: { "$ref": "#/components/schemas/SharedUser" },
              flare_tag: { "$ref": "#/components/schemas/ArticleFlareTag" },
              organization: { "$ref": "#/components/schemas/SharedOrganization" }
            },
            required: %w[type_of id title description cover_image readable_publish_date
                         social_image tag_list tags slug path url canonical_url comments_count
                         positive_reactions_count public_reactions_count created_at edited_at
                         crossposted_at published_at last_comment_at published_timestamp user
                         reading_time_minutes]
          },
          SharedUser: {
            description: "The resource creator",
            type: "object",
            properties: {
              name: { type: :string },
              username: { type: :string },
              twitter_username: { type: :string, nullable: true },
              github_username: { type: :string, nullable: true },
              website_url: { type: :string, format: :url, nullable: true },
              profile_image: { description: "Profile image (640x640)", type: :string },
              profile_image_90: { description: "Profile image (90x90)", type: :string }
            }
          },
          SharedOrganization: {
            description: "The organization the resource belongs to",
            type: "object",
            properties: {
              name: { type: :string },
              username: { type: :string },
              slug: { type: :string },
              profile_image: { description: "Profile image (640x640)", type: :string, format: :url },
              profile_image_90: { description: "Profile image (90x90)", type: :string, format: :url }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running "rswag:specs:swaggerize".
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ":json" and ":yaml".
  config.swagger_format = :json
end

# Convenience method for creating an example section for a response section
module Rswag
  module Specs
    module ExampleGroupHelpers
      def add_examples
        after do |example|
          # No metadata to generate for empty responses like 201 and 204.
          next unless respond_to?(:response) && response&.body.present?

          # Generate the examples for the API docs.
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      end
    end
  end
end
