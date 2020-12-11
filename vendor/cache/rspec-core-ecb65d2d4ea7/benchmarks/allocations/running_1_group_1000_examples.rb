require_relative "helper"

RSpec.describe "one example group" do
  1000.times do |i|
    example "example #{i}" do
    end
  end
end

benchmark_allocations(burn: 0) do
  RSpec::Core::Runner.run([])
end

__END__

Original allocations:

                                          class_plus                                             count
-----------------------------------------------------------------------------------------------  -----
String                                                                                           35018
Array<Symbol>                                                                                    14030
Array                                                                                            12075
RSpec::Core::Hooks::HookCollection                                                                4000
Time                                                                                              2002
Array<Symbol,Proc>                                                                                2000
RSpec::Core::Hooks::AroundHookCollection                                                          2000
RSpec::Core::Notifications::ExampleNotification                                                   2000
Proc                                                                                              1065
RubyVM::Env                                                                                       1018
Array<Class>                                                                                      1006
Array<RSpec::Core::Example>                                                                       1005
RSpec::ExampleGroups::OneExampleGroup                                                             1002
Array<String>                                                                                       67
RubyVM::InstructionSequence                                                                         41
Hash                                                                                                35
Set                                                                                                 30
File                                                                                                 6

After my change:

                                          class_plus                                             count
-----------------------------------------------------------------------------------------------  -----
Array<Symbol>                                                                                    14030
String                                                                                           12967
Array                                                                                            12075
RSpec::Core::Hooks::HookCollection                                                                4000
Time                                                                                              2002
RSpec::Core::Notifications::ExampleNotification                                                   2000
Array<Symbol,Proc>                                                                                2000
RSpec::Core::Hooks::AroundHookCollection                                                          2000
Proc                                                                                              1065
RubyVM::Env                                                                                       1018
Array<Class>                                                                                      1006
Array<RSpec::Core::Example>                                                                       1005
RSpec::ExampleGroups::OneExampleGroup                                                             1002
Array<String>                                                                                       67
RubyVM::InstructionSequence                                                                         41
Hash                                                                                                35
Set                                                                                                 30
File                                                                                                 6
