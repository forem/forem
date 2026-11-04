require "open3"
require "spec_helper"
require_relative "../../../lib/local_redis/web_environment"

RSpec.describe LocalRedis::WebEnvironment do
  describe ".build" do
    it "returns an empty hash by default when no WEB_* variables are set" do
      env = { "RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=128" }
      expect(described_class.build(env)).to eq({})
    end

    it "maps valid integer and float WEB_RUBY_GC_* variables to Ruby 3.3 RUBY_GC_* settings" do
      env = {
        "WEB_RUBY_GC_HEAP_INIT_SLOTS" => "800000",
        "WEB_RUBY_GC_HEAP_1_INIT_SLOTS" => "200000",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS" => "150000",
        "WEB_RUBY_GC_HEAP_GROWTH_MAX_SLOTS" => "300000",
        "WEB_RUBY_GC_MALLOC_LIMIT" => "33554432",
        "WEB_RUBY_GC_MALLOC_LIMIT_MAX" => "100663296",
        "WEB_RUBY_GC_OLDMALLOC_LIMIT" => "33554432",
        "WEB_RUBY_GC_OLDMALLOC_LIMIT_MAX" => "100663296",
        "WEB_RUBY_GC_HEAP_GROWTH_FACTOR" => "1.25",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO" => "0.15",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO" => "0.4",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO" => "0.65",
        "WEB_RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" => "1.3",
        "WEB_RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR" => "1.4",
        "WEB_RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR" => "1.2"
      }

      expect(described_class.build(env)).to eq(
        "RUBY_GC_HEAP_0_INIT_SLOTS" => "800000",
        "RUBY_GC_HEAP_1_INIT_SLOTS" => "200000",
        "RUBY_GC_HEAP_FREE_SLOTS" => "150000",
        "RUBY_GC_HEAP_GROWTH_MAX_SLOTS" => "300000",
        "RUBY_GC_MALLOC_LIMIT" => "33554432",
        "RUBY_GC_MALLOC_LIMIT_MAX" => "100663296",
        "RUBY_GC_OLDMALLOC_LIMIT" => "33554432",
        "RUBY_GC_OLDMALLOC_LIMIT_MAX" => "100663296",
        "RUBY_GC_HEAP_GROWTH_FACTOR" => "1.25",
        "RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO" => "0.15",
        "RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO" => "0.4",
        "RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO" => "0.65",
        "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" => "1.3",
        "RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR" => "1.4",
        "RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR" => "1.2",
      )
    end

    it "takes effect on Ruby 3.3 startup when WEB_RUBY_GC_HEAP_INIT_SLOTS is applied" do
      overrides = described_class.build("WEB_RUBY_GC_HEAP_INIT_SLOTS" => "500000")
      default_out, status1 = Open3.capture2(RbConfig.ruby, "-e", "puts GC.stat_heap(0, :heap_allocatable_pages)")
      tuned_out, status2 = Open3.capture2(
        overrides, RbConfig.ruby, "-e", "puts GC.stat_heap(0, :heap_allocatable_pages)"
      )

      expect(status1).to be_success
      expect(status2).to be_success
      expect(tuned_out.to_i).to be > default_out.to_i
    end

    it "warns and ignores invalid or out-of-bounds WEB_RUBY_GC_* values" do
      env = {
        "WEB_RUBY_GC_HEAP_INIT_SLOTS" => "0",
        "WEB_RUBY_GC_MALLOC_LIMIT" => "64mb",
        "WEB_RUBY_GC_HEAP_GROWTH_FACTOR" => "0.5",
        "WEB_RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR" => "1.0",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO" => "1.25",
        "WEB_RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO" => "1.0",
        "WEB_RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" => "-1.2"
      }

      expect do
        expect(described_class.build(env)).to eq({})
      end.to output(/ignoring WEB_RUBY_GC_HEAP_INIT_SLOTS/).to_stderr
    end

    it "maps valid WEB_MALLOC_CONF (including -1 decay values) to MALLOC_CONF and rejects malformed values" do
      valid_env = { "WEB_MALLOC_CONF" => "background_thread:true,dirty_decay_ms:-1,muzzy_decay_ms:30000" }
      expect(described_class.build(valid_env)).to eq(
        "MALLOC_CONF" => "background_thread:true,dirty_decay_ms:-1,muzzy_decay_ms:30000",
      )

      invalid_env = { "WEB_MALLOC_CONF" => "background_thread=true;bad" }
      expect do
        expect(described_class.build(invalid_env)).to eq({})
      end.to output(/ignoring WEB_MALLOC_CONF/).to_stderr
    end

    it "merges WEB_YJIT_* flags into existing RUBYOPT and replaces duplicate flags" do
      env = {
        "RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=128",
        "WEB_YJIT_EXEC_MEM_SIZE" => "256",
        "WEB_YJIT_CALL_THRESHOLD" => "30",
        "WEB_YJIT_COLD_THRESHOLD" => "400000"
      }

      expect(described_class.build(env)).to eq(
        "RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=256 " \
                     "--yjit-call-threshold=30 --yjit-cold-threshold=400000",
      )
    end

    it "adds --yjit-disable when WEB_YJIT_* is set on an instance where YJIT was not already enabled" do
      env = {
        "RUBYOPT" => "-W0",
        "WEB_YJIT_EXEC_MEM_SIZE" => "192"
      }

      expect(described_class.build(env)).to eq(
        "RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=192",
      )
    end

    it "preserves enabled YJIT when RUBYOPT or RUBY_YJIT_ENABLE already enables YJIT" do
      enabled_via_flag = {
        "RUBYOPT" => "-W0 --yjit-exec-mem-size=128",
        "WEB_YJIT_EXEC_MEM_SIZE" => "192"
      }
      expect(described_class.build(enabled_via_flag)).to eq(
        "RUBYOPT" => "-W0 --yjit-exec-mem-size=192",
      )

      enabled_via_env = {
        "RUBYOPT" => "-W0",
        "RUBY_YJIT_ENABLE" => "1",
        "WEB_YJIT_EXEC_MEM_SIZE" => "192"
      }
      expect(described_class.build(enabled_via_env)).to eq(
        "RUBYOPT" => "-W0 --yjit-exec-mem-size=192",
      )
    end

    it "supports a standalone WEB_RUBYOPT override and preserves both -rbundler/setup and -r bundler/setup" do
      attached_env = {
        "RUBYOPT" => "-rbundler/setup -W0",
        "WEB_RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=256"
      }
      expect(described_class.build(attached_env)).to eq(
        "RUBYOPT" => "-rbundler/setup -W0 --yjit-disable --yjit-exec-mem-size=256",
      )

      separated_env = {
        "RUBYOPT" => "-r bundler/setup -W0",
        "WEB_RUBYOPT" => "-W0 --yjit-disable --yjit-exec-mem-size=256"
      }
      expect(described_class.build(separated_env)).to eq(
        "RUBYOPT" => "-r bundler/setup -W0 --yjit-disable --yjit-exec-mem-size=256",
      )
    end

    it "rejects an invalid WEB_RUBYOPT so a typo cannot prevent the Ruby VM from booting" do
      env = {
        "RUBYOPT" => "-W0",
        "WEB_RUBYOPT" => "-W0 --not-a-valid-ruby-flag"
      }

      expect do
        expect(described_class.build(env)).to eq({})
      end.to output(/ignoring invalid RUBYOPT candidate/).to_stderr
    end
  end
end
