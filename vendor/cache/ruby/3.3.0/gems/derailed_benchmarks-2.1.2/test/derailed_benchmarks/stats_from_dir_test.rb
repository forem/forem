# frozen_string_literal: true

require 'test_helper'

class StatsFromDirTest < ActiveSupport::TestCase
  test "empty files" do
    Dir.mktmpdir do |dir|
      dir = Pathname.new(dir)
      branch_info = {}
      branch_info["loser"]  = { desc: "Old commit", time: Time.now, file: dir.join("loser"), name: "loser" }
      branch_info["winner"] = { desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner"), name: "winner" }
      stats = DerailedBenchmarks::StatsFromDir.new(branch_info).call
      io = StringIO.new
      stats.call.banner(io: io) # Doesn't error
      assert_equal "", io.read
    end
  end

  test "that it works" do
    dir = fixtures_dir("stats/significant")
    branch_info = {}
    branch_info["loser"]  = { desc: "Old commit", time: Time.now, file: dir.join("loser.bench.txt"), name: "loser" }
    branch_info["winner"] = { desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner.bench.txt"), name: "winner" }
    stats = DerailedBenchmarks::StatsFromDir.new(branch_info).call

    newest = stats.newest
    oldest = stats.oldest

    assert newest.average < oldest.average

    assert_equal "winner", newest.name
    assert_equal "loser", oldest.name

    assert_in_delta 0.26, stats.d_max, 0.01
    assert_in_delta 0.2145966026289347, stats.d_critical, 0.00001
    assert_equal true, stats.significant?

    format = DerailedBenchmarks::StatsFromDir::FORMAT
    assert_equal "1.0062", format % stats.x_faster
    assert_equal "0.6147", format % stats.percent_faster

    assert_equal "11.3844", format % newest.median
  end

  test "histogram output" do
    dir = fixtures_dir("stats/significant")
    branch_info = {}
    branch_info["loser"]  = { desc: "Old commit", time: Time.now, file: dir.join("loser.bench.txt"), short_sha: "5594a2d" }
    branch_info["winner"] = { desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner.bench.txt"), short_sha: "f1ab117" }
    stats = DerailedBenchmarks::StatsFromDir.new(branch_info).call

    io = StringIO.new
    stats.call.banner(io)

    puts io.string

    assert_match(/11\.2 , 11\.28/, io.string)
    assert_match(/11\.8 , 11\.88/, io.string)
  end


  test "alignment" do
    dir = fixtures_dir("stats/significant")
    branch_info = {}
    branch_info["loser"]  = { desc: "Old commit", time: Time.now, file: dir.join("loser.bench.txt"), name: "loser" }
    branch_info["winner"] = { desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner.bench.txt"), name: "winner" }
    stats = DerailedBenchmarks::StatsFromDir.new(branch_info).call
    def stats.percent_faster
      -0.1
    end

    def stats.x_faster
      0.9922
    end

    assert_equal 1, stats.align.length
  end

  test "banner faster" do
    dir = fixtures_dir("stats/significant")
    Branch_info = {}

    require 'ostruct'
    commits = []
    commits << OpenStruct.new({ desc: "Old commit", time: Time.now, file: dir.join("loser.bench.txt"), ref: "loser", short_sha: "aaaaa" })
    commits << OpenStruct.new({ desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner.bench.txt"), ref: "winner", short_sha: "bbbbb" })
    stats = DerailedBenchmarks::StatsFromDir.new(commits).call
    newest = stats.newest
    oldest = stats.oldest

    # Test fixture for banner
    def stats.d_max
      "0.037"
    end

    def stats.d_critical
      "0.001"
    end

    def newest.median
      10.5
    end

    def oldest.median
      11.0
    end

    expected = <<-EOM
[bbbbb] (10.5000 seconds) "I am the new commit" ref: "winner"
  FASTER 🚀🚀🚀 by:
    1.0476x [older/newer]
    4.5455% [(older - newer) / older * 100]
[aaaaa] (11.0000 seconds) "Old commit" ref: "loser"
EOM

    actual = StringIO.new
    stats.banner(actual)

    assert_match expected, actual.string
  end

  test "banner slower" do
    dir = fixtures_dir("stats/significant")
    branch_info = {}
    branch_info["loser"]  = { desc: "I am the new commit", time: Time.now, file: dir.join("loser.bench.txt"), name: "loser" }
    branch_info["winner"] = { desc: "Old commit", time: Time.now - 10, file: dir.join("winner.bench.txt"), name: "winner" }
    stats = DerailedBenchmarks::StatsFromDir.new(branch_info).call
    newest = stats.newest
    oldest = stats.oldest

    def oldest.median
      10.5
    end

    def newest.median
      11.0
    end

    expected = <<-EOM
[loser] (11.0000 seconds) "I am the new commit" ref: "loser"
  SLOWER 🐢🐢🐢 by:
     0.9545x [older/newer]
    -4.7619% [(older - newer) / older * 100]
[winner] (10.5000 seconds) "Old commit" ref: "winner"
EOM

    actual = StringIO.new
    stats.banner(actual)

    assert_match expected, actual.string
  end

  test "stats from samples with slightly different sizes" do
    stats = DerailedBenchmarks::StatsFromDir.new({})
    out = stats.statistical_test([100,101,102, 100, 101, 99], [1,3, 3, 2])
    assert out[:alternative]
  end
end
