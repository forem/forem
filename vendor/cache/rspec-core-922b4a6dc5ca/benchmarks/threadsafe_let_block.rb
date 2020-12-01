require 'rspec/core'
require 'rspec/expectations'

# switches between these implementations - https://github.com/rspec/rspec-core/pull/1858/files
# benchmark requested in this PR         - https://github.com/rspec/rspec-core/pull/1858
#
# I ran these from lib root by adding "gem 'benchmark-ips'" to ../Gemfile-custom
# then ran `bundle install --standalone --binstubs bundle/bin`
# then ran `ruby --disable-gems -I lib -I "$PWD/bundle" -r bundler/setup -S benchmarks/threadsafe_let_block.rb`

# The old, non-thread safe implementation, imported from the `main` branch and pared down.
module OriginalNonThreadSafeMemoizedHelpers
  def __memoized
    @__memoized ||= {}
  end

  module ClassMethods
    def let(name, &block)
      # We have to pass the block directly to `define_method` to
      # allow it to use method constructs like `super` and `return`.
      raise "#let or #subject called without a block" if block.nil?
      OriginalNonThreadSafeMemoizedHelpers.module_for(self).__send__(:define_method, name, &block)

      # Apply the memoization. The method has been defined in an ancestor
      # module so we can use `super` here to get the value.
      if block.arity == 1
        define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(RSpec.current_example, &nil) } }
      else
        define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(&nil) } }
      end
    end
  end

  def self.module_for(example_group)
    get_constant_or_yield(example_group, :LetDefinitions) do
      mod = Module.new do
        include Module.new {
          example_group.const_set(:NamedSubjectPreventSuper, self)
        }
      end

      example_group.const_set(:LetDefinitions, mod)
      mod
    end
  end

  # @private
  def self.define_helpers_on(example_group)
    example_group.__send__(:include, module_for(example_group))
  end

  def self.get_constant_or_yield(example_group, name)
    if example_group.const_defined?(name, (check_ancestors = false))
      example_group.const_get(name, check_ancestors)
    else
      yield
    end
  end
end

class HostBase
  # wires the implementation
  # adds `let(:name) { nil }`
  # returns `Class.new(self) { let(:name) { super() } }`
  def self.prepare_using(memoized_helpers, options={})
    include memoized_helpers
    extend memoized_helpers::ClassMethods
    memoized_helpers.define_helpers_on(self)

    define_method(:initialize, &options[:initialize]) if options[:initialize]
    let(:name) { nil }

    verify_memoizes memoized_helpers, options[:verify]

    Class.new(self) do
      memoized_helpers.define_helpers_on(self)
      let(:name) { super() }
    end
  end

  def self.verify_memoizes(memoized_helpers, additional_verification)
    # Since we're using custom code, ensure it actually memoizes as we expect...
    counter_class = Class.new(self) do
      include RSpec::Matchers
      memoized_helpers.define_helpers_on(self)
      counter = 0
      let(:count) { counter += 1 }
    end
    extend RSpec::Matchers

    instance_1 = counter_class.new
    expect(instance_1.count).to eq(1)
    expect(instance_1.count).to eq(1)

    instance_2 = counter_class.new
    expect(instance_2.count).to eq(2)
    expect(instance_2.count).to eq(2)

    instance_3 = counter_class.new
    instance_3.instance_eval &additional_verification if additional_verification
  end
end

class OriginalNonThreadSafeHost < HostBase
  Subclass = prepare_using OriginalNonThreadSafeMemoizedHelpers
end

class ThreadSafeHost < HostBase
  Subclass = prepare_using RSpec::Core::MemoizedHelpers,
    :initialize => lambda { |*| @__memoized = ThreadsafeMemoized.new },
    :verify     => lambda { |*| expect(__memoized).to be_a_kind_of RSpec::Core::MemoizedHelpers::ThreadsafeMemoized }
end

class ConfigNonThreadSafeHost < HostBase
  Subclass = prepare_using RSpec::Core::MemoizedHelpers,
    :initialize => lambda { |*| @__memoized = NonThreadSafeMemoized.new },
    :verify     => lambda { |*| expect(__memoized).to be_a_kind_of RSpec::Core::MemoizedHelpers::NonThreadSafeMemoized }
end

def title(title)
  hr    = "#" * (title.length + 6)
  blank = "#  #{' ' * title.length}  #"
  [hr, blank, "#  #{title}  #", blank, hr]
end

require 'benchmark/ips'

puts title "versions"
puts "RUBY_VERSION             #{RUBY_VERSION}"
puts "RUBY_PLATFORM            #{RUBY_PLATFORM}"
puts "RUBY_ENGINE              #{RUBY_ENGINE}"
puts "ruby -v                  #{`ruby -v`}"
puts "Benchmark::IPS::VERSION  #{Benchmark::IPS::VERSION}"
puts "rspec-core SHA           #{`git log --pretty=format:%H -1`}"
puts

puts title "1 call to let -- each sets the value"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") { OriginalNonThreadSafeHost.new.name }
  x.report("non-threadsafe (config)  ") { ConfigNonThreadSafeHost.new.name }
  x.report("threadsafe               ") { ThreadSafeHost.new.name }
  x.compare!
end

puts title "10 calls to let -- 9 will find memoized value"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") do
    i = OriginalNonThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe (config)  ") do
    i = ConfigNonThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("threadsafe               ") do
    i = ThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.compare!
end

puts title "1 call to let which invokes super"

Benchmark.ips do |x|
  x.report("non-threadsafe (original)") { OriginalNonThreadSafeHost::Subclass.new.name }
  x.report("non-threadsafe (config)  ") { ConfigNonThreadSafeHost::Subclass.new.name }
  x.report("threadsafe               ") { ThreadSafeHost::Subclass.new.name }
  x.compare!
end

puts title "10 calls to let which invokes super"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") do
    i = OriginalNonThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe (config)  ") do
    i = ConfigNonThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("threadsafe               ") do
    i = ThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.compare!
end

__END__

##############
#            #
#  versions  #
#            #
##############
RUBY_VERSION             2.2.0
RUBY_PLATFORM            x86_64-darwin13
RUBY_ENGINE              ruby
ruby -v                  ruby 2.2.0p0 (2014-12-25 revision 49005) [x86_64-darwin13]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           1ee7a8d8cde6ba2dd13d35e90e824e8e5ba7db76

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
non-threadsafe (original)
                        53.722k i/100ms
non-threadsafe (config)
                        44.998k i/100ms
threadsafe
                        26.123k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        830.988k (± 6.3%) i/s -      4.190M
non-threadsafe (config)
                        665.662k (± 6.7%) i/s -      3.330M
threadsafe
                        323.575k (± 5.6%) i/s -      1.620M

Comparison:
non-threadsafe (original):   830988.5 i/s
non-threadsafe (config)  :   665661.9 i/s - 1.25x slower
threadsafe               :   323574.9 i/s - 2.57x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
non-threadsafe (original)
                        28.724k i/100ms
non-threadsafe (config)
                        25.357k i/100ms
threadsafe
                        18.349k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        346.302k (± 6.1%) i/s -      1.752M
non-threadsafe (config)
                        309.970k (± 5.4%) i/s -      1.547M
threadsafe
                        208.946k (± 5.2%) i/s -      1.046M

Comparison:
non-threadsafe (original):   346302.0 i/s
non-threadsafe (config)  :   309970.2 i/s - 1.12x slower
threadsafe               :   208946.3 i/s - 1.66x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
non-threadsafe (original)
                        42.458k i/100ms
non-threadsafe (config)
                        37.367k i/100ms
threadsafe
                        21.088k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        591.906k (± 6.3%) i/s -      2.972M
non-threadsafe (config)
                        511.295k (± 4.7%) i/s -      2.578M
threadsafe
                        246.080k (± 5.8%) i/s -      1.244M

Comparison:
non-threadsafe (original):   591906.3 i/s
non-threadsafe (config)  :   511295.0 i/s - 1.16x slower
threadsafe               :   246079.6 i/s - 2.41x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
non-threadsafe (original)
                        24.282k i/100ms
non-threadsafe (config)
                        22.762k i/100ms
threadsafe
                        14.685k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        297.423k (± 5.0%) i/s -      1.505M
non-threadsafe (config)
                        264.046k (± 5.6%) i/s -      1.320M
threadsafe
                        170.853k (± 4.7%) i/s -    866.415k

Comparison:
non-threadsafe (original):   297422.6 i/s
non-threadsafe (config)  :   264045.8 i/s - 1.13x slower
threadsafe               :   170853.1 i/s - 1.74x slower
