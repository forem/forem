# rubocop:disable Metrics/BlockLength
namespace :forem_native do
  desc "Compile the forem_native Rust extension into gems/forem_native/lib/forem_native"
  task compile: :environment do
    require "forem_native"
    abort("Failed to compile forem_native (is `cargo` installed?)") unless ForemNative::Builder.compile!
    ForemNative.load_native!
    puts "Compiled #{ForemNative::Builder.extension_binary_path} (available?: #{ForemNative.available?})"
  end

  desc "Run Rust unit tests and Clippy lints for forem_native"
  task rust_test: :environment do
    require "forem_native"
    Dir.chdir(ForemNative::Builder::GEM_ROOT) do
      sh "cargo test --workspace"
      sh "cargo clippy --workspace --all-targets -- -D warnings"
    end
  end

  desc "Clean compiled Rust artifacts and staged shared libraries"
  task clean: :environment do
    require "forem_native"
    FileUtils.rm_f(ForemNative::Builder.extension_binary_path)
    Dir.chdir(ForemNative::Builder::GEM_ROOT) do
      sh "cargo clean" if ForemNative::Builder.cargo_available?
    end
  end

  desc "Run throughput (benchmark-ips) and allocation (memory_profiler) benchmarks for forem_native"
  task benchmark: :environment do
    require "benchmark/ips"
    require "memory_profiler"

    unless ForemNative.available?
      puts "Compiling forem_native first..."
      Rake::Task["forem_native:compile"].invoke
    end

    sample_markdown = <<~MD * 60
      ---
      title: Rewriting Rails Hot Paths in Rust with Magnus
      published: true
      tags: ruby, rust, performance, rails
      ---

      ## Why In-Process Native Extensions Matter

      In a high-traffic Rails application like Forem, allocation-heavy string transformations
      create thousands of transient Ruby String and Array objects on every article render.
      By moving pure compute into `forem_core` and exposing it via `magnus`, we eliminate
      heap allocations and speed up execution by an order of magnitude! 🚀
    MD

    legacy_ruby_calculate = lambda do |content|
      (content.to_s.split(/\W+/).count / 275.0).ceil
    end

    ruby_mem = MemoryProfiler.report { 10.times { legacy_ruby_calculate.call(sample_markdown) } }
    rust_mem = MemoryProfiler.report { 10.times { ForemNative.calculate_reading_time(sample_markdown) } }

    puts "Sample size: #{sample_markdown.bytesize} bytes (#{ForemNative.split_word_count(sample_markdown)} tokens)"
    puts "Ruby Legacy allocations (10 runs): " \
         "#{ruby_mem.total_allocated} objects (#{ruby_mem.total_allocated_memsize} bytes)"
    puts "Rust Magnus allocations (10 runs): " \
         "#{rust_mem.total_allocated} objects (#{rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby (legacy split + count)") do
        legacy_ruby_calculate.call(sample_markdown)
      end
      x.report("Rust (magnus + forem_core)") do
        ForemNative.calculate_reading_time(sample_markdown)
      end
      x.compare!
    end
  end
end
# rubocop:enable Metrics/BlockLength
