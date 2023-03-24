class ApplicationDecorator
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON

  delegate_missing_to :@object

  # ActiveModel compatibility
  delegate :to_param, :to_partial_path, :current_page, :total_pages,
           :limit_value, :total_count, :entry_name, :offset_value,
           :last_page?, to: :@object

  attr_reader :object

  def self.decorate_collection(objects)
    objects.map(&:decorate)
  end

  def initialize(object)
    @object = object
  end

  def decorated?
    true
  end

  # A convenience/optimiization method.
  #
  # @return [ApplicationDecorator]
  #
  # @note Without this method, the @object will handle the `decorate` message; which will go through
  #       the logic of determining the decorator class, and instantiating a new decorator.
  def decorate
    self
  end
end
