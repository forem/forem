group :specs, halt_on_fail: true do
  guard :rspec, cmd: "bundle exec rspec" do
    require "guard/rspec/dsl"
    dsl = Guard::RSpec::Dsl.new(self)

    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_files)
    watch(rspec.spec_helper) { rspec.spec_dir }
    watch(rspec.spec_support) { rspec.spec_dir }

    # Ruby files
    dsl.watch_spec_files_for(dsl.ruby.lib_files)

    watch(%r{^(lib/guard/rspec/template)s/Guardfile$}) do
      rspec.spec.call("lib/guard/rspec/template")
    end

    watch(%r{^lib/guard/rspec/dsl.rb$}) do
      rspec.spec.call("lib/guard/rspec/template")
    end
  end

  guard :rubocop, all_on_start: false do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end
