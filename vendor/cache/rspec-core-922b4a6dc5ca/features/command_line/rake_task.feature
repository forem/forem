Feature: rake task

  RSpec ships with a rake task with a number of useful options.

  We recommend you wrap this in a `rescue` clause so that you can
  use your `Rakefile` in an environment where RSpec is unavailable
  (for example on a production server). e.g:

  ```ruby
  begin
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:spec)
  rescue LoadError
  end
  ```

  Scenario: Default options with passing spec (prints command and exit status is 0)
    Given a file named "Rakefile" with:
      """ruby

      begin
        require 'rspec/core/rake_task'

        RSpec::Core::RakeTask.new(:spec)

        task :default => :spec
      rescue LoadError
        # no rspec available
      end
      """
    And a file named "spec/thing_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "does something" do
          # pass
        end
      end
      """
    When I run `rake`
    Then the output should match:
      """
      (ruby(\d\.\d(.\d)?)?|rbx) -I\S+ [\/\S]+\/exe\/rspec
      """
    Then the exit status should be 0

  Scenario: Default options with failing spec (exit status is 1)
    Given a file named "Rakefile" with:
      """ruby
      begin
        require 'rspec/core/rake_task'

        RSpec::Core::RakeTask.new(:spec)

        task :default => :spec
      rescue LoadError
        # no rspec available
      end
      """
    And a file named "spec/thing_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "does something" do
          fail
        end
      end
      """
    When I run `rake`
    Then the exit status should be 1

  Scenario: Setting `fail_on_error = false` with failing spec (exit status is 0)
    Given a file named "Rakefile" with:
      """ruby
      begin
        require 'rspec/core/rake_task'

        RSpec::Core::RakeTask.new(:spec) do |t|
          t.fail_on_error = false
        end

        task :default => :spec
      rescue LoadError
        # no rspec available
      end
      """
    And a file named "spec/thing_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "does something" do
          fail
        end
      end
      """
    When I run `rake`
    Then the exit status should be 0

  Scenario: Passing arguments to the `rspec` command using `rspec_opts`
    Given a file named "Rakefile" with:
      """ruby
      begin
        require 'rspec/core/rake_task'

        RSpec::Core::RakeTask.new(:spec) do |t|
          t.rspec_opts = "--tag fast"
        end
      rescue LoadError
        # no rspec available
      end
      """
    And a file named "spec/thing_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "has a tag", :fast => true do
          # pass
        end

        it "does not have a tag" do
          fail
        end
      end
      """
    When I run `rake spec`
    Then the exit status should be 0
    Then the output should match:
      """
      (ruby(\d\.\d(.\d)?)?|rbx) -I\S+ [\/\S]+\/exe\/rspec --pattern spec[\/\\*{,}]+_spec.rb --tag fast
      """

  Scenario: Passing rake task arguments to the `rspec` command via `rspec_opts`
    Given a file named "Rakefile" with:
      """ruby
      begin
        require 'rspec/core/rake_task'

        RSpec::Core::RakeTask.new(:spec, :tag) do |t, task_args|
          t.rspec_opts = "--tag #{task_args[:tag]}"
        end
      rescue LoadError
        # no rspec available
      end
      """
    And a file named "spec/thing_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "has a tag", :fast => true do
          # pass
        end

        it "does not have a tag" do
          fail
        end
      end
      """
    When I run `rake spec[fast]`
    Then the exit status should be 0
    Then the output should match:
      """
      (ruby(\d\.\d(.\d)?)?|rbx) -I\S+ [\/\S]+\/exe\/rspec --pattern spec[\/\\*{,}]+_spec.rb --tag fast
      """
