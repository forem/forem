# This class is responsible for helping to build a menu.
#
# @see AdminMenu
class Menu
  # @return [Hash<Symbol, Menu::Scope>]
  def self.define(&block)
    builder = new
    builder.instance_exec(&block)
    builder.items
  end

  attr_reader :items

  def initialize
    @items = {}
  end

  # @param name [String]
  # @param svg [String]
  # @param children [Array<Hash>]
  def scope(name, svg, children)
    @items[name] = Scope.new(name: name, svg: "#{svg}.svg", children: children)
  end

  # @see Menu::Item#initialize for details on the parameters.
  # @return [Menu::Item]
  def item(...)
    Item.new(...)
  end

  class Scope
    attr_reader :name, :svg, :children

    def initialize(name:, svg:, children:)
      @name = name
      @svg = svg
      @children = children
    end

    # Does this Scope have multiple children?  From a presentation stand point
    # we render menu items with multiple children a bit differently than those
    # with only one child.
    #
    # @return [TrueClass] when this item has more than 1 child.
    # @return [FalseClass] when this item has one or less children.
    def has_multiple_children?
      @children.length > 1
    end

    # @return [TrueClass] when this item has at least one child.
    # @return [FalseClass] when this item has no children.
    def has_children?
      !@children.empty?
    end
  end

  class Item
    attr_reader :name, :controller, :children, :parent

    # @param name [String]
    # @param controller [String]
    # @param children [Array<Hash>]
    # @param visible [Boolean, #call]
    # @param parent [NilClass, String]
    def initialize(name:, controller: name, children: [], visible: true, parent: nil)
      @name = name
      @controller = controller.tr(" ", "_")
      @children = children
      @visible = visible
      @parent = parent
    end

    # @return [TrueClass] if this menu item should be visible
    # @return [FalseClass] if this menu item should not be visible
    def visible?
      if @visible.respond_to?(:call)
        @visible.call
      else
        @visible
      end
    end

    alias visible visible?

    # @return [TrueClass] when this item has more than 1 child.
    # @return [FalseClass] when this item has one or less children.
    def has_multiple_children?
      @children.length > 1
    end

    # @return [TrueClass] when this item has at least one child.
    # @return [FalseClass] when this item has no children.
    def has_children?
      !@children.empty?
    end
  end
end
