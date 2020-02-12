class BaseDecorator
  delegate_missing_to :@record

  def initialize(record)
    @record = record
  end
end
