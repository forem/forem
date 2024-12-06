module FieldTest
  class Engine < ::Rails::Engine
    isolate_namespace FieldTest

    # prevents conflict with field_test method in views
    engine_name "field_test_engine"
  end
end
