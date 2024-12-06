# frozen_string_literal: true

require 'test_helper'

class GitSwitchProjectTest < ActiveSupport::TestCase
  test "tells me when it's not pointing at a git project" do
    exception = assert_raises {
      DerailedBenchmarks::Git::SwitchProject.new(path: "/dev/null")
    }
    assert_includes(exception.message, '.git directory')
  end

  test "dirty gemspec cleaning" do
    Dir.mktmpdir do |dir|
      run!("git clone https://github.com/sharpstone/default_ruby #{dir} 2>&1 && cd #{dir} && git checkout 6e642963acec0ff64af51bd6fba8db3c4176ed6e 2>&1 && git checkout -b mybranch 2>&1")
      run!("cd #{dir} && echo lol > foo.gemspec && git add .")

      io = StringIO.new
      project = DerailedBenchmarks::Git::SwitchProject.new(path: dir, io: io)

      assert project.dirty?
      refute project.clean?

      project.restore_branch_on_return do
        project.commits.map(&:checkout!)
      end

      assert_includes io.string, "Bundler modifies gemspec files"
      assert_includes io.string, "Applying stash"
    end
  end

  test "works on a git repo" do
    Dir.mktmpdir do |dir|
      run!("git clone https://github.com/sharpstone/default_ruby #{dir} 2>&1 && cd #{dir} && git checkout 6e642963acec0ff64af51bd6fba8db3c4176ed6e 2>&1 && git checkout -b mybranch 2>&1")

      # finds shas when none given
      project = DerailedBenchmarks::Git::SwitchProject.new(path: dir)

      assert_equal ["6e642963acec0ff64af51bd6fba8db3c4176ed6e", "da748a59340be8b950e7bbbfb32077eb67d70c3c"], project.commits.map(&:ref)
      first_commit = project.commits.first

      assert_equal "CI test support", first_commit.description
      assert_equal "6e64296", first_commit.short_sha
      assert_equal "/dev/null/6e642963acec0ff64af51bd6fba8db3c4176ed6e.bench.txt", first_commit.log.to_s
      assert_equal DateTime.parse("Tue, 14 Apr 2020 13:26:03 -0500"), first_commit.time

      assert_equal "mybranch", project.current_branch_or_sha

      # Finds shas when 1 is given
      project = DerailedBenchmarks::Git::SwitchProject.new(path: dir, ref_array: ["da748a59340be8b950e7bbbfb32077eb67d70c3c"])

      assert_equal ["da748a59340be8b950e7bbbfb32077eb67d70c3c", "5c09f748957d2098182762004adee27d1ff83160"], project.commits.map(&:ref)


      # Returns correct refs if given
      project = DerailedBenchmarks::Git::SwitchProject.new(path: dir, ref_array: ["da748a59340be8b950e7bbbfb32077eb67d70c3c", "9b19275a592f148e2a53b87ead4ccd8c747539c9"])

      assert_equal ["da748a59340be8b950e7bbbfb32077eb67d70c3c", "9b19275a592f148e2a53b87ead4ccd8c747539c9"], project.commits.map(&:ref)

      first_commit = project.commits.first

      first_commit.checkout!

      assert_equal first_commit.short_sha, project.current_branch_or_sha

      # Test restore_branch_on_return
      project.restore_branch_on_return(quiet: true) do
        project.commits.last.checkout!

        assert_equal project.commits.last.short_sha, project.current_branch_or_sha
      end

      assert_equal project.commits.first.short_sha, project.current_branch_or_sha

      exception = assert_raise {
        DerailedBenchmarks::Git::SwitchProject.new(path: dir, ref_array: ["6e642963acec0ff64af51bd6fba8db3c4176ed6e", "mybranch"])
      }

      assert_includes(exception.message, 'Duplicate SHA resolved "6e64296"')
    end
  end
end
