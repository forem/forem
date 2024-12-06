# frozen_string_literal: true

require 'test_helper'

class KernelRequireTest < ActiveSupport::TestCase
  setup do
    require 'derailed_benchmarks/core_ext/kernel_require'
    GC.disable
  end

  teardown do
    GC.enable
    DerailedBenchmarks::RequireTree.reset!
  end

  test "profiles load" do
    in_fork do
      require fixtures_dir("require/load_parent.rb")

      parent = assert_node_in_parent("load_parent.rb", TOP_REQUIRE)

      assert_node_in_parent("load_child.rb", parent)
    end
  end

  test "profiles autoload" do
    skip if RUBY_VERSION.start_with?("2.2") # Fails on CI, I can't install Ruby 2.2 locally to debug https://stackoverflow.com/questions/63926460/install-ruby-2-2-on-mac-osx-catalina-with-ruby-install, https://github.com/postmodern/ruby-install/issues/375

    in_fork do
      require fixtures_dir("require/autoload_parent.rb")
      parent = assert_node_in_parent("autoload_parent.rb", TOP_REQUIRE)

      assert_node_in_parent("autoload_child.rb", parent)
    end
  end

  test "core extension profiles useage" do
    in_fork do
      require fixtures_dir("require/parent_one.rb")
      parent    = assert_node_in_parent("parent_one.rb", TOP_REQUIRE)
      assert_node_in_parent("child_one.rb", parent)
      child_two = assert_node_in_parent("child_two.rb", parent)
      assert_node_in_parent("relative_child", parent)
      assert_node_in_parent("relative_child_two", parent)
      assert_node_in_parent("raise_child.rb", child_two)
    end
  end

  # Checks to see that the given file name is present in the
  # parent tree node and that the memory of that file
  # is less than the parent (since the parent should include itself
  # plus its children)
  #
  # Returns the child node
  def assert_node_in_parent(file_name, parent)
    file = fixtures_dir(File.join("require", file_name))
    node = parent[file]
    assert node, "Expected: #{parent.name} to include: #{file.to_s} but it did not.\nChildren: #{parent.children.map(&:name).map(&:to_s)}"
    unless parent == TOP_REQUIRE
      assert node.cost < parent.cost, "Expected: #{node.name.inspect} (#{node.cost}) to cost less than: #{parent.name.inspect} (#{parent.cost})"
    end
    node
  end

  # Used to get semi-clean process memory
  # It would be better to run the requires in a totally different process
  # but...that would take engineering
  #
  # If I was going to do that, I would find a way to serialize RequireTree
  # into a json structure with file names and costs, run the script
  # dump the json to a file, then in this process read the file and
  # run assertions
  def in_fork
    Tempfile.create("stdout") do |tmp_file|
      pid = fork do
        $stdout.reopen(tmp_file, "w")
        $stderr.reopen(tmp_file, "w")
        $stdout.sync = true
        $stderr.sync = true
        yield
        Kernel.exit!(0) # needed for https://github.com/seattlerb/minitest/pull/683
      end
      Process.waitpid(pid)

      if $?.success?
        print File.read(tmp_file)
      else
        raise File.read(tmp_file)
      end
    end
  end
end
