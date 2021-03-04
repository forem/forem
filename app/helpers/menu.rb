class Menu
  def self.define(&block)
    builder = new
    builder.instance_exec(&block)
    builder.items
  end

  attr_reader :items

  def initialize
    @items = {}
  end

  def scope(name, children)
    @items[name] = children
  end

  def item(name:, controller: name, children: [])
    { name: name, controller: controller.gsub(" ", "_"), children: children }
  end
end
