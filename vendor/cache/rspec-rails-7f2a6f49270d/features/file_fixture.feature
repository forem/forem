Feature: file fixture
  Rails 5 adds simple access to sample files called file fixtures.
  File fixtures are normal files stored in spec/fixtures/files by default.

  File fixtures are represented as +Pathname+ objects.
  This makes it easy to extract specific information:

  ```ruby
  file_fixture("example.txt").read # get the file's content
  file_fixture("example.mp3").size # get the file size
  ```

  You can customize files location by setting
  ```ruby
  RSpec.configure do |config|
    config.file_fixture_path = "spec/custom_directory"
  end
  ```

  Scenario: Reading file content from fixtures directory
    And a file named "spec/fixtures/files/sample.txt" with:
      """
      Hello
      """

    And a file named "spec/lib/file_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "file" do
        it "reads sample file" do
          expect(file_fixture("sample.txt").read).to eq("Hello")
        end
      end
      """
    When I run `rspec spec/lib/file_spec.rb`
    Then the examples should all pass
