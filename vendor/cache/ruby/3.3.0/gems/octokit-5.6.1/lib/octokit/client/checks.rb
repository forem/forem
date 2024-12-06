# frozen_string_literal: true

module Octokit
  class Client
    # Methods for the Checks API
    #
    # @see https://developer.github.com/v3/checks/
    module Checks
      # Methods for Check Runs
      #
      # @see https://developer.github.com/v3/checks/runs/

      # Create a check run
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param name [String] The name of the check
      # @param head_sha [String] The SHA of the commit to check
      # @return [Sawyer::Resource] A hash representing the new check run
      # @see https://developer.github.com/v3/checks/runs/#create-a-check-run
      # @example Create a check run
      #   check_run = @client.create_check_run("octocat/Hello-World", "my-check", "7638417db6d59f3c431d3e1f261cc637155684cd")
      #   check_run.name # => "my-check"
      #   check_run.head_sha # => "7638417db6d59f3c431d3e1f261cc637155684cd"
      #   check_run.status # => "queued"
      def create_check_run(repo, name, head_sha, options = {})
        options[:name] = name
        options[:head_sha] = head_sha

        post "#{Repository.path repo}/check-runs", options
      end

      # Update a check run
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check run
      # @return [Sawyer::Resource] A hash representing the updated check run
      # @see https://developer.github.com/v3/checks/runs/#update-a-check-run
      # @example Update a check run
      #   check_run = @client.update_check_run("octocat/Hello-World", 51295429, status: "in_progress")
      #   check_run.id # => 51295429
      #   check_run.status # => "in_progress"
      def update_check_run(repo, id, options = {})
        patch "#{Repository.path repo}/check-runs/#{id}", options
      end

      # List check runs for a specific ref
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param ref [String] A SHA, branch name, or tag name
      # @param options [Hash] A set of optional filters
      # @option options [String] :check_name Returns check runs with the specified <tt>name</tt>
      # @option options [String] :status Returns check runs with the specified <tt>status</tt>
      # @option options [String] :filter Filters check runs by their <tt>completed_at</tt> timestamp
      # @return [Sawyer::Resource] A hash representing a collection of check runs
      # @see https://developer.github.com/v3/checks/runs/#list-check-runs-for-a-specific-ref
      # @example List check runs for a specific ref
      #   result = @client.check_runs_for_ref("octocat/Hello-World", "7638417db6d59f3c431d3e1f261cc637155684cd", status: "in_progress")
      #   result.total_count # => 1
      #   result.check_runs.count # => 1
      #   result.check_runs[0].id # => 51295429
      #   result.check_runs[0].status # => "in_progress"
      def check_runs_for_ref(repo, ref, options = {})
        paginate "#{Repository.path repo}/commits/#{ref}/check-runs", options do |data, last_response|
          data.check_runs.concat last_response.data.check_runs
          data.total_count += last_response.data.total_count
        end
      end
      alias list_check_runs_for_ref check_runs_for_ref

      # List check runs in a check suite
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check suite
      # @param options [Hash] A set of optional filters
      # @option options [String] :check_name Returns check runs with the specified <tt>name</tt>
      # @option options [String] :status Returns check runs with the specified <tt>status</tt>
      # @option options [String] :filter Filters check runs by their <tt>completed_at</tt> timestamp
      # @return [Sawyer::Resource] A hash representing a collection of check runs
      # @see https://developer.github.com/v3/checks/runs/#list-check-runs-in-a-check-suite
      # @example List check runs in a check suite
      #   result = @client.check_runs_for_check_suite("octocat/Hello-World", 50440400, status: "in_progress")
      #   result.total_count # => 1
      #   result.check_runs.count # => 1
      #   result.check_runs[0].check_suite.id # => 50440400
      #   result.check_runs[0].status # => "in_progress"
      def check_runs_for_check_suite(repo, id, options = {})
        paginate "#{Repository.path repo}/check-suites/#{id}/check-runs", options do |data, last_response|
          data.check_runs.concat last_response.data.check_runs
          data.total_count += last_response.data.total_count
        end
      end
      alias list_check_runs_for_check_suite check_runs_for_check_suite

      # Get a single check run
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check run
      # @return [Sawyer::Resource] A hash representing the check run
      # @see https://developer.github.com/v3/checks/runs/#get-a-single-check-run
      def check_run(repo, id, options = {})
        get "#{Repository.path repo}/check-runs/#{id}", options
      end

      # List annotations for a check run
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check run
      # @return [Array<Sawyer::Resource>] An array of hashes representing check run annotations
      # @see https://developer.github.com/v3/checks/runs/#list-annotations-for-a-check-run
      # @example List annotations for a check run
      #   annotations = @client.check_run_annotations("octocat/Hello-World", 51295429)
      #   annotations.count # => 1
      #   annotations[0].path # => "README.md"
      #   annotations[0].message # => "Looks good!"
      def check_run_annotations(repo, id, options = {})
        paginate "#{Repository.path repo}/check-runs/#{id}/annotations", options
      end

      # Methods for Check Suites
      #
      # @see https://developer.github.com/v3/checks/suites/

      # Get a single check suite
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check suite
      # @return [Sawyer::Resource] A hash representing the check suite
      # @see https://developer.github.com/v3/checks/suites/#get-a-single-check-suite
      def check_suite(repo, id, options = {})
        get "#{Repository.path repo}/check-suites/#{id}", options
      end

      # List check suites for a specific ref
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param ref [String] A SHA, branch name, or tag name
      # @param options [Hash] A set of optional filters
      # @option options [Integer] :app_id Filters check suites by GitHub App <tt>id</tt>
      # @option options [String] :check_name Filters checks suites by the <tt>name</tt> of the check run
      # @return [Sawyer::Resource] A hash representing a collection of check suites
      # @see https://developer.github.com/v3/checks/suites/#list-check-suites-for-a-specific-ref
      # @example List check suites for a specific ref
      #   result = @client.check_suites_for_ref("octocat/Hello-World", "7638417db6d59f3c431d3e1f261cc637155684cd", app_id: 76765)
      #   result.total_count # => 1
      #   result.check_suites.count # => 1
      #   result.check_suites[0].id # => 50440400
      #   result.check_suites[0].app.id # => 76765
      def check_suites_for_ref(repo, ref, options = {})
        paginate "#{Repository.path repo}/commits/#{ref}/check-suites", options do |data, last_response|
          data.check_suites.concat last_response.data.check_suites
          data.total_count += last_response.data.total_count
        end
      end
      alias list_check_suites_for_ref check_suites_for_ref

      # Set preferences for check suites on a repository
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param options [Hash] Preferences to set
      # @return [Sawyer::Resource] A hash representing the repository's check suite preferences
      # @see https://developer.github.com/v3/checks/suites/#set-preferences-for-check-suites-on-a-repository
      # @example Set preferences for check suites on a repository
      #   result = @client.set_check_suite_preferences("octocat/Hello-World", auto_trigger_checks: [{ app_id: 76765, setting: false }])
      #   result.preferences.auto_trigger_checks.count # => 1
      #   result.preferences.auto_trigger_checks[0].app_id # => 76765
      #   result.preferences.auto_trigger_checks[0].setting # => false
      #   result.repository.full_name # => "octocat/Hello-World"
      def set_check_suite_preferences(repo, options = {})
        patch "#{Repository.path repo}/check-suites/preferences", options
      end

      # Create a check suite
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param head_sha [String] The SHA of the commit to check
      # @return [Sawyer::Resource] A hash representing the new check suite
      # @see https://developer.github.com/v3/checks/suites/#create-a-check-suite
      # @example Create a check suite
      #   check_suite = @client.create_check_suite("octocat/Hello-World", "7638417db6d59f3c431d3e1f261cc637155684cd")
      #   check_suite.head_sha # => "7638417db6d59f3c431d3e1f261cc637155684cd"
      #   check_suite.status # => "queued"
      def create_check_suite(repo, head_sha, options = {})
        options[:head_sha] = head_sha

        post "#{Repository.path repo}/check-suites", options
      end

      # Rerequest check suite
      #
      # @param repo [Integer, String, Hash, Repository] A GitHub repository
      # @param id [Integer] The ID of the check suite
      # @return [Boolean] True if successful, raises an error otherwise
      # @see https://developer.github.com/v3/checks/suites/#rerequest-check-suite
      def rerequest_check_suite(repo, id, options = {})
        post "#{Repository.path repo}/check-suites/#{id}/rerequest", options
        true
      end
    end
  end
end
