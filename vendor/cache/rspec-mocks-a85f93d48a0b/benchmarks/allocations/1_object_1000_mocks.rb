require_relative "helper"
symbols = (1..1000).map { |x| :"#{x}" }

benchmark_allocations do
  o = Object.new
  symbols.each do |sym|
    expect(o).to receive(sym)
  end

  symbols.each do |sym|
    o.send(sym)
  end

  RSpec::Mocks.space.verify_all
  RSpec::Mocks.space.reset_all
end

__END__
As of commit 9ee3e3adb529113bf1cc75cc4424d014f880dc47:

                     class_plus                       count
----------------------------------------------------  -----
Array                                                 22003
Proc                                                   3001
RubyVM::Env                                            3001
Array<Symbol>                                          2000
String                                                 2000
Hash                                                   1002
RSpec::Mocks::ExpectationTarget                        1000
Enumerator                                             1000
RSpec::Mocks::Matchers::Receive                        1000
Array<Fixnum>                                          1000
RSpec::Mocks::InstanceMethodStasher                    1000
RSpec::Mocks::MethodDouble                             1000
Array<NilClass>                                        1000
RSpec::Mocks::MessageExpectation                       1000
Array<RSpec::Mocks::MethodDouble,Symbol>               1000
Array<Array>                                           1000
Array<RSpec::Mocks::ArgumentMatchers::NoArgsMatcher>   1000
Array<Symbol,Array,NilClass>                           1000
RSpec::Mocks::Proxy::SpecificMessage                   1000
RSpec::Mocks::Implementation                           1000
Array<Class,Module>                                       1
RSpec::Mocks::PartialDoubleProxy                          1
RSpec::Mocks::ErrorGenerator                              1
Array<RSpec::Mocks::PartialDoubleProxy>                   1


After PR #936:

                     class_plus                       count
----------------------------------------------------  -----
Array                                                 21003
RubyVM::Env                                            3001
Proc                                                   3001
String                                                 2000
RSpec::Mocks::InstanceMethodStasher                    1000
RSpec::Mocks::Matchers::Receive                        1000
RSpec::Mocks::ExpectationTarget                        1000
RSpec::Mocks::Implementation                           1000
RSpec::Mocks::MessageExpectation                       1000
RSpec::Mocks::MethodDouble                             1000
Array<Symbol>                                          1000
Array<RSpec::Mocks::MethodDouble,Symbol>               1000
Array<Array>                                           1000
Enumerator                                             1000
Array<RSpec::Mocks::ArgumentMatchers::NoArgsMatcher>   1000
Array<Symbol,Array,NilClass>                           1000
RSpec::Mocks::Proxy::SpecificMessage                   1000
Array<NilClass>                                        1000
Array<Fixnum>                                          1000
Hash                                                      2
RSpec::Mocks::PartialDoubleProxy                          1
Array<RSpec::Mocks::PartialDoubleProxy>                   1
RSpec::Mocks::ErrorGenerator                              1
Array<Class,Module>                                       1
