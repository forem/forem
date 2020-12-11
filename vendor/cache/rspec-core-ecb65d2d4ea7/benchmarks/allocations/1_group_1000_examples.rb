require_relative "helper"

benchmark_allocations do
  RSpec.describe "one example group" do
    1000.times do |i|
      example "example #{i}" do
      end
    end
  end
end

__END__

Original stats:

               class_plus                 count
----------------------------------------  -----
String                                    22046
Hash                                       3006
Array<String>                              3002
Proc                                       2007
RubyVM::Env                                2007
Array                                      1013
Regexp                                     1001
RSpec::Core::Example::ExecutionResult      1001
Array<String,Fixnum>                       1001
RSpec::Core::Example                       1000
RSpec::Core::Metadata::ExampleHash         1000
RSpec::Core::Hooks::HookCollection            6
MatchData                                     4
Array<Module>                                 2
Module                                        2
RSpec::Core::Metadata::ExampleGroupHash       1
RSpec::Core::Hooks::AroundHookCollection      1
Class                                         1
Array<Hash>                                   1
RSpec::Core::Hooks::HookCollections           1
Array<RSpec::Core::Example>                   1

After my fixes:

               class_plus                 count
----------------------------------------  -----
String                                     6030
Hash                                       3006
Array<String>                              3002
RubyVM::Env                                2007
Proc                                       2007
Array                                      1013
RSpec::Core::Example::ExecutionResult      1001
Array<String,Fixnum>                       1001
RSpec::Core::Metadata::ExampleHash         1000
RSpec::Core::Example                       1000
RSpec::Core::Hooks::HookCollection            6
MatchData                                     4
Module                                        2
Array<Module>                                 2
RSpec::Core::Hooks::HookCollections           1
Array<RSpec::Core::Example>                   1
RSpec::Core::Hooks::AroundHookCollection      1
RSpec::Core::Metadata::ExampleGroupHash       1
Class                                         1
Array<Hash>                                   1
