module SmartProperties
  class PropertyCollection
    include Enumerable

    attr_reader :parent

    def self.for(scope)
      parents = scope.ancestors[1..-1].select do |ancestor|
        ancestor.ancestors.include?(SmartProperties) &&
          ancestor != scope &&
          ancestor != SmartProperties
      end

      collection = new

      parents.reverse.each do |parent|
        parent.properties.register(collection)
      end

      collection
    end

    def initialize
      @collection = {}
      @collection_with_parent_collection = {}
      @children = []
    end

    def []=(name, value)
      name = name.to_s
      collection[name] = value
      collection_with_parent_collection[name] = value
      notify_children
      value
    end

    def [](name)
      collection_with_parent_collection[name.to_s]
    end

    def key?(name)
      collection_with_parent_collection.key?(name.to_s)
    end

    def keys
      collection_with_parent_collection.keys.map(&:to_sym)
    end

    def values
      collection_with_parent_collection.values
    end

    def each(&block)
      return to_enum(:each) if block.nil?
      collection_with_parent_collection.each { |name, value| block.call([name.to_sym, value]) }
    end

    def to_hash
      Hash[each.to_a]
    end

    def register(child)
      children.push(child)
      child.refresh(collection_with_parent_collection)
      nil
    end

    protected

    attr_accessor :children
    attr_accessor :collection
    attr_accessor :collection_with_parent_collection

    def notify_children
      @children.each { |child| child.refresh(collection_with_parent_collection) }
    end

    def refresh(parent_collection)
      @collection_with_parent_collection.merge!(parent_collection)
      notify_children
      nil
    end
  end
end
