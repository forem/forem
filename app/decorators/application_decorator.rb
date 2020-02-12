class ApplicationDecorator
  delegate_missing_to :@object

  attr_reader :object

  def initialize(object)
    @object = object
  end

  def decorated?
    true
  end

  def self.decorate_collection(objects)
    objects.map(&:decorate)
  end
end
