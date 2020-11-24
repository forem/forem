module Ransack
  class Ransacker

    attr_reader :name, :type, :formatter, :args

    delegate :call, :to => :@callable

    def initialize(klass, name, opts = {}, &block)
      @klass, @name = klass, name

      @type = opts[:type] || :string
      @args = opts[:args] || [:parent]
      @formatter = opts[:formatter]
      @callable = opts[:callable] || block ||
                  (@klass.method(name) if @klass.respond_to?(name)) ||
                  proc { |parent| parent.table[name] }
    end

    def attr_from(bindable)
      call(*args.map { |arg| bindable.send(arg) })
    end

  end
end
