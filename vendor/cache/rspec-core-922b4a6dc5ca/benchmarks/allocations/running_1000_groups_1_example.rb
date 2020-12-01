require_relative "helper"

1000.times do |i|
  RSpec.describe "group #{i}" do
    it "has one example" do
    end
  end
end

benchmark_allocations(burn: 0, min_allocations: 50) do
  RSpec::Core::Runner.run([])
end

__END__

Before optimization:

                                          class_plus                                             count
-----------------------------------------------------------------------------------------------  -----
Array<Symbol>                                                                                    26021
String                                                                                           21331
Array                                                                                            19402
Array<Symbol,Proc>                                                                                6001
Array<RSpec::Core::Example>                                                                       6001
RSpec::Core::Hooks::HookCollection                                                                4004
Array<Class>                                                                                      4004
Hash                                                                                              3098
Proc                                                                                              3096
RubyVM::Env                                                                                       3056
Time                                                                                              2002
Random                                                                                            2001
RSpec::Core::Hooks::AroundHookCollection                                                          2000
RSpec::Core::Notifications::GroupNotification                                                     2000
RSpec::Core::Notifications::ExampleNotification                                                   2000
RSpec::Core::Hooks::GroupHookCollection                                                           2000
Array<Symbol,TrueClass>                                                                           1003
Array<Class,Module>                                                                               1002
Array<TrueClass>                                                                                  1002
RSpec::Core::Example::Procsy                                                                      1000
RubyVM::InstructionSequence                                                                        506
Array<Fixnum,FalseClass>                                                                           391
Array<Array>                                                                                       205
Array<String>                                                                                       52


After optimization, we allocate 2000 less arrays and 2000 less RSpec::Core::Hooks::HookCollection
instances. That's 2 less of each per example group.

                                          class_plus                                             count
-----------------------------------------------------------------------------------------------  -----
Array<Symbol>                                                                                    26021
String                                                                                           21331
Array                                                                                            17400
Array<Symbol,Proc>                                                                                6001
Array<RSpec::Core::Example>                                                                       6001
Array<Class>                                                                                      4004
Hash                                                                                              3098
Proc                                                                                              3096
RubyVM::Env                                                                                       3056
RSpec::Core::Hooks::HookCollection                                                                2002
Time                                                                                              2002
Random                                                                                            2001
RSpec::Core::Notifications::ExampleNotification                                                   2000
RSpec::Core::Notifications::GroupNotification                                                     2000
RSpec::Core::Hooks::GroupHookCollection                                                           2000
Array<Symbol,TrueClass>                                                                           1003
Array<Class,Module>                                                                               1002
Array<TrueClass>                                                                                  1002
RSpec::Core::Example::Procsy                                                                      1000
RSpec::Core::Hooks::AroundHookCollection                                                          1000
RubyVM::InstructionSequence                                                                        506
Array<Fixnum,FalseClass>                                                                           391
Array<Array>                                                                                       205
Array<String>                                                                                       52

After yet further optimization (where HookCollection instances are only created when hooks are added),
we've reduced allocations significantly further:

                                          class_plus                                             count
-----------------------------------------------------------------------------------------------  -----
String                                                                                           21332
Array                                                                                            13412
Array<Symbol>                                                                                     6021
Array<Symbol,Proc>                                                                                6001
Array<RSpec::Core::Example>                                                                       6001
Hash                                                                                              3105
Array<Class>                                                                                      3004
Proc                                                                                              2101
RubyVM::Env                                                                                       2061
Time                                                                                              2002
Random                                                                                            2001
RSpec::Core::Notifications::GroupNotification                                                     2000
RSpec::Core::Notifications::ExampleNotification                                                   2000
Array<Symbol,TrueClass>                                                                           1003
Array<Class,Module>                                                                               1002
Array<TrueClass>                                                                                  1002
RubyVM::InstructionSequence                                                                        506
Array<Fixnum,FalseClass>                                                                           391
Array<Array>                                                                                       208
Array<String>                                                                                       52
