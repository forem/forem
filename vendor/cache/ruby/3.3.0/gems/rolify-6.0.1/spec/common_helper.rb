require 'test-unit'

begin
  require 'pry'
rescue LoadError
end

# `Test::Unit::AutoRunner.need_auto_run=` was introduced to the test-unit
# gem in version 2.4.9. Previous to this version `Test::Unit.run=` was
# used. The implementation of test-unit included with Ruby has neither
# method.
if defined? Test::Unit::AutoRunner
  Test::Unit::AutoRunner.need_auto_run = false
elsif defined?(Test::Unit)
  Test::Unit.run = false
end
