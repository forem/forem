class ApplicationDecorator
  delegate_missing_to :@object

  attr_reader :object

  def initialize(object)
    @object = object
  end

  def self.decoratecollection(objects)
    objects.map(&:decorate)
  end
end
