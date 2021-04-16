class Menu
  # Used to build the data structure for the Admin Menu model.

  def self.define(&block)
    builder = new
    builder.instance_exec(&block)
    builder.items
  end

  attr_reader :items

  def initialize
    @items = {}
  end

  def scope(name, svg, children)
    @items[name] = { svg: "#{svg}.svg", children: children }
  end

  def item(name:, controller: name, children: [], visible: true)
    { name: name, controller: controller.tr(" ", "_"), children: children, visible: visible }
  end
end
