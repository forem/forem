1.29.0 / 2024-02-26
==================

New functionality and features
------------------------------

  * Add support for `context` parameter in `url_for_direct_upload`
  * Add support for `use_fetch_format` parameter in `cl_video_tag`
  * Add support for `fields` parameter in Search and Admin APIs
  * Add support for access keys management in Account Provisioning API

Other Changes
-------------

  * Avoid early loading of `ActionView::Base`
  * Fix `sqlite3` dependency version
  * Add Rails 7.x to supported versions on `README.md`

1.28.0 / 2023-11-06
==================

New functionality and features
------------------------------

  * Add support for `image_file` parameter in `visual_search` Admin API
  * Add support for `on_success` upload parameter

Other Changes
-------------

  * Replace `update_all` to `update_column` in CarrierWave storage

1.27.0 / 2023-07-31
==================

New functionality and features
------------------------------

  * Add support for `visual_search` Admin API
  * Add support for Search URL
  * Add support for `SearchFolders` API
  * Add support for `media_metadata` API parameter

1.26.0 / 2023-06-01
==================

New functionality and features
------------------------------

  * Add support for related assets Admin APIs
  * Add support for expressions in `start_offset` and `end_offset` parameters
  * Add support for Conditional Metadata Rules API
  * Add support for large files in Active Storage

1.25.0 / 2023-01-04
==================

* Add support for `mount_uploaders` in `CarrierWave`

1.24.0 / 2022-12-06
==================

New functionality and features
------------------------------

  * Add support for `resources_by_asset_folder` Admin API
  * Add support for `asset_folder`, `display_name` and `unique_display_name` parameters
  * Add support for `use_asset_folder_as_public_id_prefix` parameter
  * Add support for `metadata` in `update` Admin API
  * Add support for `clear_invalid` metadata parameter

Other Changes
-------------

  * Fix Active Storage public id of the raw asset handling
  * Fix Active Storage resource type for direct upload
  * Fix CarrierWave identifier obtainment

1.23.0 / 2022-04-05
==================

New functionality and features
------------------------------

  * Add support for multiple ACLs in `AuthToken`
  * Add support for disable b-frames for video codec
  * Add support for aliases in Configuration
  * Add support for `filename` upload parameter

Other Changes
-------------

  * Fix escaping of special characters in `public_id`
  * Fix support of the lowercase response headers
  * Fix CarrierWave file retrieval after store

1.22.0 / 2022-02-17
==================

New functionality and features
------------------------------

  * Add support for OAuth authentication
  * Add support for Dynamic Folder upload parameters
  * Add support for `reorder_metadata_fields` Admin API
  * Add support for `resources_by_asset_ids` Admin API
  * Add support for `resource_by_asset_id` Admin API
  * Add support for fetch url in overlay
  * Add support for Ruby 3.0
  * Add missing docstrings for Admin API methods

Other Changes
-------------

  * Ignore `URL` in `AuthToken` generation when `ACL` is provided
  * Update `README`
  * Add tests for expression normalization
  * Update Travis with current Ruby versions

1.21.0 / 2021-08-23
==================

New functionality and features
------------------------------

  * Add support for `create_slideshow` Upload API
  * Add support for variables in text style
  * Add support for `context` and `metadata` in `rename` Upload API
  * Add support for `reorder_metadata_field_datasource` Admin API
  * Add `verify_api_response_signature` and `verify_notification_signature` helpers
  * Add `download_generated_sprite` and `download_multi` methods
  * Add support for `urls` in multi and sprite APIs
  * Add support for `live` parameter in upload presets
  * Add support for `metadata` parameter in `resources` Admin APIs

Other Changes
-------------

  * Fix `transformations` API call
  * Fix named parameters normalization issue
  * Remove duplicates in Search Api fields
  * Improve configuration tests
  * Add tests for Provisioning API
  * Refactor metadata usage in tests
  * Update GitHub templates

1.20.0 / 2021-03-26
==================

New functionality and features
------------------------------

  * Add support for `download_backedup_asset` helper method
  * Add support for `filename_override` upload parameter
  * Add support for `SHA-256` algorithm in auth signatures
    
Other Changes
-------------

* Fix `type` parameter support in ActiveStorage service
* Fix expression normalization in advanced cases
* Add test for context metadata as user variables
* Improve validation of auth token generation


1.19.0 / 2021-03-05
==================

New functionality and features
------------------------------

* Add Account Provisioning API
* Add support for `api_proxy` parameter
* Add support for `date` parameter in `usage`  Admin API

Other Changes
-------------

* Fix direct upload of raw files
* Improve unit testing of add-ons
* Change test for `eval` upload parameter
* Bump vulnerable version of rubyzip
* Fix `cloudinary.gemspec` glob issue

1.18.1 / 2020-09-30
===================

  * Update embedded `jquery.cloudinary.js` to fix ES5 compatibility issue

1.18.0 / 2020-09-27
===================

New functionality and features
------------------------------
  * Add `download_folder` helper
  * Add support for `sources` in `video` tag
  * Add structured metadata to Admin and Upload API
  
Other Changes
-------------
  * Fix download of a raw file in ActiveStorage
  * Update embedded `jquery.cloudinary.js` to fix ES5 compatibility issue
  
1.17.1 / 2020-08-25
===================

  * Fix options handling issue in SassC

1.17.0 / 2020-08-21
===================

New functionality and features
------------------------------

  * Add support for `eval` upload parameter
  * Add support for 32-char signature length
  
Other Changes
-------------

  * Fix escaping of query string characters in CarrierWave integration
  * Fix detection integration test
  * Integrate with sub-account test service
  * Add pull request template

1.16.1 / 2020-07-06
===================

  * Detect data URLs with suffix in mime type
  * Fix `Invalid regular expression` error in Safari

1.16.0 / 2020-06-29
===================

New functionality and features
------------------------------

  * Add support for uploading `StringIO`

Other Changes
-------------

  * Set default cache storage to `file` in `CarrierWave`
  * Fix `normalize_expression` to ignore predefined variables
  * Fix sample projects

1.15.0 / 2020-06-11
===================

New functionality and features
------------------------------

  * Add support for `accessibility_analysis` parameter
  
Other Changes
-------------
  * Fix `download` function in `Cloudinary::CarrierWave`
  * Fix handling of empty value in `if` parameter
  * Fix consumption of configuration from environment variables

1.14.0 / 2020-05-06
===================

New functionality and features
------------------------------

  * Add support of global folder in ActiveStorage
  * Add duration to conditions in video

Other Changes
-------------

  * Fix `URI.unescape is obsolete` warning
  * Fix lingering Rails 6 autoload warnings
  * Fix Ruby 1.9 CI build
  * Allow setting uploader timeout to `nil`
  * Update link to CarrierWave integration
  * Update issue templates

1.13.2 / 2020-01-19
===================

  * Fix asset extension detection in active storage service `url` method

1.13.1 / 2019-11-24
===================

  * Remove `test_files` from `gemspec`
  * Remove redundant binary files from `active_storage` spec
  * Fix `rspec` deprecation warnings in Rails 6
  * Add test for uploading IO

1.13.0 / 2019-11-14
===================

New functionality and features
------------------------------
  * Add `SassC` `cloudinary-url` function
  
Other Changes
-------------

  * Fix ActiveStorage download not using `ssl` for `https`
  * Fix resource type detection in ActiveStorage
  * Fix `storage_type` instance method in `Cloudinary::CarrierWave` module
  * Fix sample project, limit sqlite3 to a compatible version

1.12.0 / 2019-10-02
=============

New functionality and features
------------------------------

  * Add Cloudinary service for ActiveStorage
  * Add `create_folder` Admin API method
  * Add `delete_folder` Admin API method
  * Add `cinemagraph_analysis` to `upload`, `explicit` and `resource` API methods
  * Add `font_antialiasing` and `font_hinting` text style parameters
  * Add `derived_next_cursor` parameter to `resource` Admin API
  * Add `next_cursor` and `max_results` for `root_folders` and `subfolders` Admin API functions
  * Add `jpeg` to `IMAGE_FORMATS`
  * Add `pow` transformation operator
  * Add `force_version` to `cloudinary_url`
  * Support per corner values for the `radius` transformation parameter
  * Support using multiple resource types when generating archives
  * Support Google Storage fetch URL
  
Other Changes
-------------
  * Ensure `CLOUDINARY_URL` starts with `cloudinary://`
  * Reduce memory usage in `Cloudinary::Utils.cloudinary_url`
  * Encode URL in Admin API methods
  * Fix base64 data validation
  * Return `video` as the `resource_type` for audio files
  * Add language and platform version for ruby/rails user agent
  * Fix TravisCI configuration for ruby 1.9
  

1.11.1 / 2018-12-22
===================

  * Merge pull request #330 from langsharpe/constant_nil_is_deprecated
    * Replace `NIL` with `Nil` to fix ruby 2.4 deprecation warning

1.11.0 / 2018-12-12
===================

New functionality and features
------------------------------

  * Support new parameters and values:
      * `auto` keyword in the `start_offset` 
      * `art` artistic effect
      * `fps`
      * `quality_analysis`
      * `quality_override`
      * `pre` custom function transformation 
  * Add namespace to the cloudinary controller to avoiding conflicts (#319)

Other Changes
-------------

  * Add "Join the Community"
  * Merge pull request #290 from zenspider/fix_carrierwave_deps
      * Fixed direct references to ::CarrierWave with `defined?` guards.
      * Fix debugging output to use mutex so output isn't garbled.

1.10.1-rc / 2018-11-20
======================

  * Fix transformation list test
  * Fix detection test
  * Remove encrypted variables from .travis.yml
  * Update dependencies
  * Support "pre" versions in update_version

1.10.0 / 2018-11-08
===================

New functionality and features
------------------------------

  * Add the `custom_function` transformation parameter
  * Add Picture and source tags
  * Add `srcset` attribute to image tag
  * Add support for overlays of type fetch
  * Add breakpoints cache

Other Changes
-------------

  * Add `update_version` script
  * Fix transformations test
  * Replace ruby list notation to support older ruby versions
  * Refactor tests
  * Replace REXML  with Nokogiri
  * Un-ignore the lib folder
  * Ignore empty transformations when processing an array of transformations
  * Restore configuration after each test
  * Limit Rack version to fix compatibility issues with ruby 1.9.3
  * Fix context escaping in call_context_api
  * Fix uploadLarge to use X-Unique-Upload-Id
  * Add test cases of OCR for upload and URL generation
  * Add test case of conditional tags
  * Fix expected result in cname with cdn_subdomain test
  * Fix raw conversion test
  * Raise exception when api-secret is missing in signed-url flow

1.9.1 / 2018-03-06
==================

  * Add instructions for using the source code. Fixes #291 and #292
  * Fix check for CarrierWave in `Migrator`. Fixes #286
  * Fix acl and url escaping in auth_token generation

1.9.0 / 2018-02-27
==================

New functionality and features
------------------------------

  * Add `access_control` parameter to `upload` and `update`
  * Add `format` to CarrierWave plug-in's `PreloadedFile` 

Other Changes
-------------

  * Fix upload categorization test

1.8.3 / 2018-02-04
==================

  * Suppress warnings in tests
  * Support symbols in `context`
  * Remove `auto_tagging` failure test
  * Fix fully_unescape
  * Whitespace
  * Fixed CW versions to use stored_version of original PR #263

1.8.2 / 2017-11-22
==================

  * Fix URL signature
  * Use the correct method for updating a column
  * Add support for `named` parameter in list transformation API
  * load environment when running sync_static task
  * Fix the overwritten initializer for hash (#273)
  * Force TravisCI to install bundler
  * Fix CloudinaryFile::exists? method. Solves #193 #205
  * Update Readme to point to HTTPS URLs of cloudinary.com

1.8.1 / 2017-05-16
==================

  * Fix `image_path`. Fixes #257
  * Add Auto Gravity modes tests.
  * Use correct values in Search tests

1.8.0 / 2017-05-01
==================

New functionality and features
------------------------------

  * Add Search API
  * Sync static for non image assets (#241) fixes #27

Other Changes
-------------

  * Fix Carrierwave signed URL.

1.7.0 / 2017-04-09
==================

New functionality and features
------------------------------

  * Added resource publishing API
    * `Api.publish_by_prefix`
    * `Api.publish_by_tag`
    * `Api.publish_by_ids`
  * Support remote URLs in `Uploader.upload_large` API
  * Add missing parameters to generate-archive
    * `skip_transformation_name`
    * `allow_missing`
  * Added context API methods
    * `Api.add_context`
    * `Api.remove_all_context`
  * Added `Uploader.remove_all_tags` method
  * Support URL SEO suffix for authenticated images
  * Add support of "format" parameter to responsive-breakpoints hash
  * Add notification_url to update API
  

Other Changes
-------------

  * Remove tag from test
  * Change test criteria from changing versions to bytes
  * Use `TRAVIS_JOB_ID` if available or random. Move auth test constants to spec_helper.
  * Add test for deleting public IDs which contain commas
  * Move expression and replacement to constants
  * Don't normalize negative numbers
  * Added generic aliasing to methods named with image
  * Added Private annotation to certain utility methods
  * Add `encode_context` method to `Utils`
  * Escape = and | characters in context values + test
  * Add more complex eager test cases
  * Switch alias_method_chain to alias_method to support Rails version >5.1

1.6.0 / 2017-03-08
==================

New functionality and features
------------------------------

  * Support user defined variables
  * Add `to_type` parameter to the rename method (#236)
  * Add `async` parameter to the upload method (#235)

Other Changes
-------------

  * Switch ow & oh to iw & ih on respective test case
  * test auto gravity transformation in URL build

1.5.2 / 2017-02-22
==================

  * Support URL Authorization token. 
  * Rename auth_token. 
  * Support nested keys in CLOUDINARY_URL
  * Support "authenticated" url without a signature.
  * Add OpenStruct from ruby 2.0.
  * Add specific rubyzip version for ruby 1.9

1.5.1 / 2017-02-13
==================
  * Fix Carrierwave 1.0.0 integration: broken `remote_image_url`

1.5.0 / 2017-02-07
==================

New functionality and features
------------------------------

  * Access mode API

Other Changes
-------------

  * Fix transformation related tests.
  * Fix archive test to use `include` instead of `match_array`.
  * Fix "missing folder" test
  * Add specific dependency on nokogiri
  * Update rspec version

1.4.0 / 2017-01-30
==================

  * Add Akamai token generator
  * Merge pull request #201 from nashby/fix-image-formats
  * Remove video formats from the image formats array.

1.3.0 / 2016-12-22
==================

New functionality and features
------------------------------

  * Search resource by context
  * Add `:transformations` parameter to all `delete_resources`
  * Update bundled Cloudinary Javascript library to 2.1.8 

Other Changes
-------------

  * Added 'Album' for better showing a real world use case
  * Use tag instead of content_tag when creating input tag
  * Fix `face_coordinates` test

1.2.4 / 2016-10-30
==================

New functionality and features
------------------------------

  * Add `Api.update_streaming_profile`
  * Add `Api.get_streaming_profile`
  * Add `Api.delete_streaming_profile`
  * Add `Api.list_streaming_profiles`
  * Add `Api.create_streaming_profile`

1.2.3 / 2016-08-21
==================

  * Allow a string to be passed as eager transformation
  * Add `delete_derived_by_transformation` to the Api methods.
  * Support videos mode for url suffixes. 
  * Support url suffixes without private cdn
  * Fix `values_match?`

1.2.2 / 2016-07-16
==================

  * Update gemspec to differentiate between ruby 1.9 and 2.0
  * Add `:max_results => 500` to tags test.
  * Add json spec. Add explicit exception names to `raise_error`.

1.2.1 / 2016-07-16
==================

  * Add test for width and height values "ow", "oh"
  * Include new JavaScript files. Related to cloudinary/cloudinary_js#73

1.2.0 / 2016-06-22
==================

New functionality and features
------------------------------

  * New configuration parameter `:client_hints`
  * Enhanced auto `width` values
  * Enhanced `quality` values

Other Changes
-------------

  * Remove coffee and map files. Fixes #203

1.1.7 / 2016-06-06
==================

New functionality and features
------------------------------
  * Add TravisCI configuration and label
  * Add `keyframe_interval` and `streaming_profile` transformation parameters
  * Add `expires_at` parameter to `Utils#download_archive_url`
  * Add `CONTRIBUTING.md`
  * Add `next_cursor` to `transformation()`
  * Update Readme with information on the Cloudinary JavaScript library. Related to #199

Other Changes
-------------
  
  * Ensuring rails environment is loaded as a dependency of running sync_static rake task, so anything initializer that sets up Cloudinary.config takes affect
  * Refactor tests to allow parallel runs.
  * Fix `deep_hash_values` matcher.
  * Mock heavy tests
  * Remove upload_presets created during the tests
  * Merge pull request #177 from Buyapowa/fix-rake-task-config-loading
  * Merge pull request #185 from gunterja/patch-1
  * Merge pull request #186 from gunterja/patch-2
  * Merge pull request #187 from gunterja/patch-3
  * Merge pull request #189 from gunterja/patch-5
  * Merge branch 'task/add-next-cursor-to-transformation'
  * adding tests for next_cursor with transformation 
  * Merge pull request #192 from thedrow/patch-1
  * exists? must return booleans
  * `File.exists?` is deprecated in favor of `File.exist?`

1.1.6 / 2016-04-20
==================

  * Fix CarrierWave integration - update without new upload saves identifier with resource_type and type
  * Fixed tests

1.1.5 / 2016-04-12
==================

  * Add `url_suffix` support for private images.
  * Replace explicit twitter test with explicit transformation
  * Fix "should allow listing resources by start date" test

1.1.4 / 2016-03-22
==================

New functionality and features
------------------------------

  * Add conditional transformation

Other Changes
-------------

  * Fix direct upload in the sample project

1.1.3 / 2016-03-16
==================

  * Update known file types.
  * Use `upload` params in `explicit` for forward compatibility.
  * Change `LAYER_KEYWORD_PARAMS` to array to explicitly declare the order.
  * Add comment regarding the `allow_implicit_crop_mode`.
  * Use `target_tags` to specify tags for the created archive.
  * Fix mapping test.

1.1.2 / 2015-12-16
==================

  * Support new archive (ZIP) creation API:
    * Uploader: `create_archive`, `create_zip`.
    * Utils: `download_archive_url`, `download_zip_url`
    * Helper: `cl_download_archive_url`, `cl_download_zip_url`.
  * Use basic to_query implementation when Rails is not available.
  * Allow chained transformations and eager transformations to process width & height when crop is not defined.
  * Apply style and whitespaces.
  * Remove redundant variable. Replace if ! with until.
  * Apply style and whitespaces.
  * Remove redundant variable
  * Add `:invalidate` option to `Cloudinary::Uploader.rename`
  * Add line spacing to text layer
  * Add upload mapping
  * Add `Cloudinary::Api.restore`
  * Add `deep_hash_values` matcher. Add `invalidate` test to `explicit`
  * Add `Cloudinary.user_platform`
  * Merge branch 'feature/breakpoints_and_zip'
  * Add test for `Cloudinary::Uploader.create_zip`
  * Refactor `create_archive`. Rename `generate_zip_download_url`. Create `download_archive_url`. Add cleanup to spec code.
  * Add condition to `image_tag` and `image_path` aliasing.
  * Add `archive_spec.rb`. Add rubyzip development dependency.
  * Add `Cloudinary::` to `Utils` calls
  * Fix temp file name in spec. Re-enable deletion of resources after the test.
  * Add deprecation warning to `zip_download_url`
  * Fix rake `build` dependency to `cloudinary:fetch_assets`
  * Apply `symbolize_keys`
  * Support the aspect_ratio transformation parameter
  * Support responsive_breakpoints JSON parameter in upload and explicit API

1.1.1 / 2015-12-04
==================

  * Add support for **overlay** and **underlay** options.
  * Add **correct escaping of text in layers**
  * Escape layer text twice. Unescape parameters before signing URL.
  * JavaScript
    * Recode `fetch_assets` task to **fetch JS files from the latest *release* rather than mater.**
    * Use new Cloudinary JS library release.
    * Update Blueimp jQuery File Upload version.
    * File `load-image.min.js` renamed `load-image.all.min.js`
  * Tests
    * Add RSpec matchers for Cloudinary URL
    * Add `TEST_TAG`. Define failure message in `produce_url`. Replace 'test_cloudinary_url' with custom matchers.
    * Add `to_be_served_by_cloudinary` matcher.
    * Test signing with layers.
  * Normalize values to string. Mark private methods as private.
  * Merge pull request #171 from pdipietro/master
    * if order changed for performance reasons; minor changes on Readme
    * added **support for Neo4j** in carrierwave/storage
  * Merge pull request #164 from ahastudio/readme-remove-wrong-prompts
    * Remove prompts in ruby file.
  * Merge pull request #39 from henrik/patch-1
    * README: example of passing auth manually.
  * Check definition and value of `::Rails::VERSION::MAJOR` and `::ActiveRecord::VERSION::MAJOR` instead of Rails.version etc. Fixes #154.
  * Thanks @henrik, @pdipietro and @ahastudio!

1.1.0 - 2015-04-21
==================

  * Pull request #136 - Update `process.rb` to ensure name value is an array.
  * CarrierWave
    * Store `resource_type` and `type` (aka `storage_type`) in carrierwave column for better support of non-image resource types and non-upload types
    * only pass format to Cloudinary when explicitly requested
    * Support disabling new extended identifier format
  * Use upload endpoint instead of upload_chunked
  * Remove `symoblize_keys` monkey patching
  * Update Rspec dependency.
  * Fix markup in the readme file.
  * Add `.gitignore` to each sample project. Add files required for testing.
  * Fix changelog format (missing newline)

1.0.85 - 2015-04-08
==================

  * Remove symoblize_keys intrusive implementation.
  * Use upload API endpoint instead of upload_chunked.

1.0.84 - 2015-03-29
==================

  * Fixed sources tag url.
  * Added video thumbnail and video tags to the sample project.
  * CHANGELOG renamed to CHANGELOG.md

1.0.83 - 2015-03-22
==================

  * Added Video Support
    * `cl_video_tag` creates an HTML video tag with optionally inner `source` tags
    * `cl_video_path` provides a url to the video resource
    * `cl_video_thumbnail_tag` creates an `img` tag with a video thumbnail and
    * `cl_video_thumbnail_path` provides a url to the video resource's thumbnail
  * Added `:zoom` transformation parameter
  * Applied Pull Requests:
    * Fix image closing tags  [#144](https://github.com/cloudinary/cloudinary_gem/issues/144)
    * Fix callback path.  [#138](https://github.com/cloudinary/cloudinary_gem/issues/138)
  * Update Cloudinary's jQuery plugin to v1.0.22.
  * Update .gitignore file

1.0.82 - 2015-02-05
==================

  * Solve problem with CarrierWave integration to newer versions on the mongoid and carrierwave-mongoid gems.
  * Enable root path for shared CDN:
    * Modified restriction in utils so that it doesn't fail for root path with shared CDN.
    * Added Object::present? predicate. Check if Object::present doesn't exist before defining it.
  * Checking for `defined?(Rails)` is not enough if we want to invoke `Rails.version` etc. It was changed to `defined? Rails::version`.

1.0.81 - 2015-01-08
==================

  * CarrierWave - support default_format if format is unknown, support arbitrary format for resource_type raw.

1.0.80 - 2015-01-01
==================

  * Support upload_chunked direct upload for large raw files.

1.0.79 - 2014-12-11
==================

  * Support folder listing API.
  * Add support for conditional processing in CarrierWave plugin.
  * Support tags in upload_large.
  * Support url_suffix and use_root_path for private_cdn URL building.
  * Allow using sign_url with type authenticated.
  * Don't sign version component by default.
  * Support for new domain sharding syntax and secure domain sharding. Support for secure_cdn_subdomain flag.
  * Update Cloudinary's jQuery plugin to v1.0.21.

1.0.78 - 2014-11-04
==================

  * Add app_root method that handled Rails.root, which is a String in old Rails versions.
  * Issue  [#127](https://github.com/cloudinary/cloudinary_gem/issues/127) - solve cyclical dependency in case cloudinary was included after Rails was initialized.

1.0.77 - 2014-09-22
==================

  * Update Cloudinary's jQuery plugin to v1.0.20.
  * Support invalidation in bulk deletion requests.

1.0.76 - 2014-08-24
==================

  * Added supported image types for rake cloudinary:sync_static.

1.0.75 - 2014-07-30
==================

  * Don't use Rails' image_tag for repsponsive/hidpi to prevent wrong alt and data URIs.

1.0.74 - 2014-07-14
==================

  * Support custom_coordinates in upload and update. Support coordinates in resource details.
  * Support delete_by_token for direct uploads.
  * Support shorthand blank for cl_image_tag with responsive/hidpi.
  * Correctly encode one-level double arrays.
  * Support non-upload resources in signed_preloaded_image (Issue  [#117](https://github.com/cloudinary/cloudinary_gem/issues/117)).
  * Support background removal upload and admin API parameter.
  * Update Cloudinary's jQuery plugin to v1.0.19.

1.0.73 - 2014-06-30
==================

  * Support dpr transformation parameter.
  * Support automatic dpr (for HiDPI) and automatic width (for responsive).
  * Accept timestamp parameter in upload method options.
  * Support pHash info in admin API.
  * Support the multiple upload flag directly in cl_image_upload_tag.
  * 'secure' configuration parameter from environment variable.
  * Make api_key and api_secret optional in unsigned upload.
  * Support the case Rails is defined but Rails.root isn't.

1.0.72 - 2014-04-15
==================

  * Fixing broken sign_request.

1.0.71 - 2014-04-15
==================

  * Upload preset support.
  * Unsigned upload support.
  * phash upload parameter support.
  * Resource listing by start_at support.
  * Updating to jQuery plugin v1.0.14.

1.0.70 - 2014-03-25
==================

  * Support upload_large without public_id.
  * Remove public_id from method parameters.
  * Backward compatibility for old upload_large API.
  * Issue  [#95](https://github.com/cloudinary/cloudinary_gem/issues/95) - exception when using storage_type :private
  * Updating to jQuery plugin v1.0.13.

1.0.69 - 2014-02-25
==================

  * Admin API update method.
  * Admin API listing by moderation kind and status.
  * Support moderation status in admin API listing.
  * Support moderation flag in upload.
  * New upload and update API parameters: moderation, ocr, raw_conversion, categorization, detection, similarity_search and auto_tagging.
  * Allow CloudinaryHelper to be included into standalone classes.
  * Added support for Sequel models using CarrierWave.

1.0.68 - 2014-02-16
==================

  * Support for uploading large raw files.
  * Correct support for image_tag and image_path override.
  * Add direction support to Admin API listings.

1.0.67 - 2014-01-09
==================

  * Support specifying face coordinates in upload API.
  * Support specifying context (currently alt and caption) in upload API and returning context in API.
  * Support specifying allowed image formats in upload API.
  * Support listing resources in admin API by multiple public IDs.
  * Send User-Agent header with client library version in API request.
  * Support for signed-URLs to override restricted dynamic URLs.

1.0.66 - 2013-11-14
==================

  * Support overwrite flag in upload
  * Support tags flag in resources_by_tag
  * Support for deletion cursor and delete all

1.0.65 - 2013-11-04
==================

  * Support for unique_filename upload parameter
  * Support the color parameter
  * Support for uploading Pathname
  * Support for stored files
  * Updated Cloudinary's jQuery plugin to v1.0.11: Support color parameter

1.0.64 - 2013-10-17
==================

  * Extracted upload_tag_params and upload_url from image_upload_tag. Extracted common code to sign_request.
  * Updated Cloudinary's jQuery plugin to v1.0.10: Binding jQuery file upload events.
  * Support line_spacing text parameter.
  * Added code documentation for cl_image_tag.

1.0.63 - 2013-08-07
==================

  * Support folder parameter.
  * Escape non-http public_ids.
  * Correct escaping of space and '-'.

1.0.62 - 2013-07-30
==================

  * Change secure urls to use *res.cloudinary.com.

1.0.61 - 2013-07-18
==================

  * Mongoid 4 compatibility fix.
  * Support raw data URI.
  * Issue  [#81](https://github.com/cloudinary/cloudinary_gem/issues/81) - Error on bootstrap + rails under Rails 4.
  * Support admin ping API.
  * Include updated jQuery plugin.

1.0.60 - 2013-07-01
==================

  * Upgrade to latest jQuery file upload.
  * Support whitelisted S3 URLs in upload.

1.0.59 - 2013-06-13
==================

  * Support discard_original_filename.
  * Support proxy parameter in upload.

1.0.58 - 2013-05-16
==================

  * cloudinary_url helper should protect options from modification.
  * Add jpc jp2 psd to list of support image formats.
  * Crop mode lfill support.

1.0.57 - 2013-05-01
==================

  * Allow my_public_id to be called from versions.
  * Fix for giving :version parameters to url in version while overriding public_id.

1.0.56 - 2013-04-24
==================

  * Support for uploading raw files in direct upload with CarrierWave.
  * Support overriding stored version.

1.0.55 - 2013-04-19
==================

  * Support folders in PreloadedFile.
  * Allow cloudinary helpers to work directly with CarrierWave uploaders.
  * Issue  [#70](https://github.com/cloudinary/cloudinary_gem/issues/70) - Return parsed error message for 401,403 and 404 error codes as well.
  * CarrierWave - allow returning format in dynamic methods.

1.0.54 - 2013-04-05
==================

  * Support auto-rename when public_id has random component.

1.0.53 - 2013-04-04
==================

  * Fix handling of non-fetch http urls.
  * Support attachment flag in private download links.

1.0.52 - 2013-03-29
==================

  * Support for unsafe transformation update (Admin API).

1.0.51 - 2013-03-28
==================

  * Fixing issue  [#66](https://github.com/cloudinary/cloudinary_gem/issues/66) - folder names are not respected in non-direct uploads.
  * Fixing issue  [#65](https://github.com/cloudinary/cloudinary_gem/issues/65) - allow overwriting existing images when updating preloaded images.
  * Support ERB in cloudinary.yml.

1.0.50 - 2013-03-24
==================

  * Support folders.
  * Short URLs.
  * Auto rename of preloaded resources in CarrierWave.

1.0.49 - 2013-03-21
==================

  * Support for renaming public_ids.
  * Safe handling of booleans to prevent issues with Firefox json deserialization.
  * Uploader tests.

1.0.48 - 2013-03-20
==================

  * Add missing require of rest_client.
  * Support for rails4 sass asset path integration.
  * Flag to prevent cloudinary from downloading remote urls directly.
  * Issue  [#61](https://github.com/cloudinary/cloudinary_gem/issues/61) build_upload_params destructively updates options.

1.0.47 - 2013-03-14
==================

  * Allow overriding config with nil/false.
  * Akamai CDN support.

1.0.46 - 2013-03-10
==================

  * Support for tags flag in resources listing API.
  * Initial partial support for Rails 4.

1.0.45 - 2013-02-28
==================

  * Ignore blank URI to support empty string in remote_image_url.
  * Issue  [#48](https://github.com/cloudinary/cloudinary_gem/issues/48) - Allow carrier wave upload to be given to url/image methods.
  * Support for explode and multi API. Support async and notification, Correctly delete raw resources uploaded via CarrierWave.

1.0.44 - 2013-02-05
==================

  * Support new usage API call.
  * Support image_metadata in upload and API.
  * Javascript index file for client side processing in jQuery File Upload.
  * Support use_filename flag.
  * Added license to the gems specification.

1.0.43 - 2012-12-18
==================

  * Support fallback to html border attribute.
  * Added Google+ Helpers.
  * Additional Helper Methods.
  * Add cl_image_path for social images.
  * Allow giving pages flag to resource details API.
  * Support opacity flag.

1.0.42 - 2012-11-14
==================

  * Raise CloudinaryException instead of string everywhere.
  * Support expires_at in private download.
  * Support info flags directly on upload.

1.0.41 - 2012-10-28
==================

  * Allow Cloudinary.config_from_url to be called before Cloudinary.config.
  * Normalize file extensions in carrier wave upload.
  * Support keep_original in resource deletion.
  * Support delete_resources_by_tag, Support for transformation flags.

1.0.40 - 2012-10-10
==================

  * Carrierwave - downcase wanted format.

1.0.39 - 2012-10-08
==================

  * Support max_results in resource drilldown.
  * Change delete_resources_by_prefix to match other signatures.
  * Add Cloudinary.config_from_url to use CLOUDINARY_URL even if not from env.

1.0.38 - 2012-10-02
==================

  * Support additional parameters (border, color space, delay).
  * Admin API enhancements.
  * Carrierwave improvments for authenticated imaged.
  * Allow URI to be used in cloudinary_url, minor fixes.

1.0.37 - 2012-09-12
==================

  * Support for customer headers.
  * Support for type in tags.
  * Support for tags in explicit.

1.0.36 - 2012-09-09
==================

  * Support storage type in CarrierWave.
  * Check if resource exists.
  * Public ID should never start with a digit
  * Authenticated resources fixes.

1.0.35 - 2012-08-27
==================

  * Fix migrator to support retrieve returning a URL.

1.0.34 - 2012-08-27
==================

  * Extract PreloadedFile for easy handling of files preloaded by the Cloudinary's jQuery library.
  * Don't pass width/height to html in case of fit/limit or angle are used.

1.0.33 - 2012-08-05
==================

  * Allow specifying angle as array.
  * Allow specifying array of transformations directly.
  * Allow using string keys in transformations.
  * Support for Cloudinary new admin API.
  * Support for signed authenticated URLs.

1.0.32 - 2012-07-26
==================

  * Fix typo in eager support for the explicit API.
  * Better handling of escaping in URL parameters.
  * Support passing transformation to all versions (process_all_versions).
  * Support private mode (make_private).

1.0.31 - 2013-07-18
==================

  * Support configurable CNAME.
  * Support for explicitly creating remote resources.

1.0.30 - 2012-07-12
==================

  * Force order of including in javascript for asset pipeline.
  * Support for ZIP download link.

1.0.29 - 2012-07-08
==================

  * Page and density parameters.
  * data-uri upload support.
  * Allow CarrierWave enable_processing.
  * Default rake task to spec & ignore Gemfile.lock.

1.0.28 - 2012-07-03
==================

  * default_public_id for CarrrierWave and JS asset packaging

1.0.27 - 2012-06-26
==================

  * Underlay support.
  * Backup flag.
  * Private resource download link.
  * Secure flag fix.
  * cloud_name param in API calls.

1.0.26 - 2012-06-08
==================

  * Fix issue 13 - rails-admin conflict.

1.0.25 - 2012-06-05
==================

  * Issues 18 (mongoid) and 19 (mount_on).

1.0.24 - 2012-05-17
==================

  * Renaming effects parameter and add numberic effect parameter.

1.0.23 - 2012-05-14
==================

  * Support fetch format and effects parameters.

1.0.21 - 2012-05-10
==================

 * Custom dynamic CarrierWave process method support.

1.0.21 - 2012-05-09
==================

  * New paramters (angle, overlay).
  * Text creation.
  * Fix issue 16.

1.0.20 - 2012-05-06
==================

  * Heroku single environment variable.

1.0.18 - 2012-05-02
==================

  * Sanitize filename for carrierwave to allow special characters in public_id.
  * Allow preloaded image with empty format (for raw files).

1.0.17 - 2012-04-28
==================

  * Fix issue 12 - tags didn't work in newer versions of carrierwave. Validate tags are not used in versions.

1.0.16 - 2012-04-25
==================

  * Background color support.
  * Add full_public_id method for accessing versioned public_id. Handle unversioned public_ids from DB.
  * Removing options passed to image_path from cl_image_path.
  * Better handling of public_id from stored value.
  * Major CarrierWave plugin cleanup. Fix issue 10. Allow overriding public_id with dynamic public_id. Allow overriding delete_remote? to prevent deleting resources from Cloudinary.
  * Fix issue  [#11](https://github.com/cloudinary/cloudinary_gem/issues/11) - nil input to image_tag throws exception.
  * Fix docs, fix sass require.

1.0.15 - 2012-04-23
==================

  * Avoiding id attributes on hidden fields.
  * Skip hidden tags for empty values.
  * cl_form_tag: avoiding id attributes on hidden fields.
  * Update timestamp in static file only if uploaded. Allow single hash in :eager. Do not consume options in :transformation.
  * Remove active_support dependency from static.
  * Always return original source if cloudinary is not used.
  * Support cloudinary-url function in sass.
  * Cleaner depdency check for sass and sass-rails.

1.0.14 - 2012-04-23
==================

  * Remove depenedency on active support.
  * Allow non-Rails use of cloudinary.yml.
  * Fix update of local url in carrir wave.
  * Allow supplying DELETE_MISSING flag in static rake task.
  * Disable recreate_versions! as it is not needed.

1.0.13 - 2012-04-22
==================

  * Default image support.

1.0.12 - 2012-04-19
==================

  * Fixing resize_to_pad to be resize_and_pad.

1.0.11 - 2012-04-19
==================

  * Better config initialization.
  * Fix bug when non-static resource is requested and a static resource existing with the same name.
  * Gravatar support.

1.0.10 - 2012-04-18
==================

  * Initial tests. Size option fix.
  * Better rails dependency support.
  * First version of cloudinary_js integration including file upload.

1.0.9 - 2012-04-16
==================

  * Support chained transformations.

1.0.8 - 2012-04-15
==================

  * Support subdomain in CDN according to public id crc32.

1.0.7 - 2012-04-12
==================

  * Issue  [#2](https://github.com/cloudinary/cloudinary_gem/issues/2): Adding support to Mongoid and fixing to_json issue.

1.0.6 - 2012-04-11
==================

  * Adding cl_form_tag and fixing old and non rails compatibliltiy issues.

1.0.5 - 2012-04-10
==================

  * Fixing radius parameter.

1.0.4 - 2012-04-04
==================

  * Static assets: progress printing in sync task, whitelist of image extensions.

1.0.3 - 2012-04-02
==================

  * Assets no longer include paths. Allow passing kind in upload and destroy.
  * Better defaults for type which allow working with fetch images.
  * Restore eager format fix.
  * Add radius support.
  * Fix default handling of local images in enhanced image_tag.

1.0.2 - 2012-04-02
==================

  * Support for passing x & y parameters to crop.
  * fetch_image_tag and escaping support.
  * Static file support.
  * Better static sync deletion support. Better image_path integration. Fix access to image_tag with non-relative path.
  * Handle case of file going into trash and back into folder before delete.
  * Readded migrator. Reduce concurrency for old versions of ruby.

1.0.1 - 2012-03-12
==================

  * Replace Array() with safer method.
  * Support passing format as part of the eager transformation.

1.0.0 - 2012-02-22
==================

  * Initial public version.

  
