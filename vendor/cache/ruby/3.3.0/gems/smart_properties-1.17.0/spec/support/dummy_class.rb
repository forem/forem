class << (DummyClass = BasicObject.new)
  def new(superclass = ::Object, class_name = 'Dummy', &block)
    c = ::Class.new(superclass) { include ::SmartProperties }
    c.define_singleton_method(:name) { class_name }
    c.class_eval(&block) if block
    c
  end
end

