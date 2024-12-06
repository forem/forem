module Rpush
  def self.plugin(name)
    plugins[name] ||= Rpush::Plugin.new(name)
    plugins[name]
  end

  def self.plugins
    @plugins ||= {}
  end

  class Plugin
    attr_reader :name, :config, :init_block
    attr_accessor :url, :description

    def initialize(name)
      @name = name
      @url = nil
      @description = nil
      @config = OpenStruct.new
      @reflection_collection = Rpush::ReflectionCollection.new
      @init_block = -> {}
    end

    def reflect
      yield(@reflection_collection)
      return if Rpush.reflection_stack.include?(@reflection_collection)
      Rpush.reflection_stack << @reflection_collection
    end

    def configure
      yield(@config)
      Rpush.config.plugin.send("#{@name}=", @config)
    end

    def init(&block)
      @init_block = block
    end

    def unload
      Rpush.reflection_stack.delete(@reflection_collection)
      Rpush.config.plugin.send("#{name}=", nil)
    end
  end
end
