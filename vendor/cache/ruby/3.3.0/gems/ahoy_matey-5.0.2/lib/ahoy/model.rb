module Ahoy
  module Model
    def visitable(name = :visit, **options)
      class_eval do
        belongs_to(name, class_name: "Ahoy::Visit", optional: true, **options)
        before_create :set_ahoy_visit
      end
      class_eval %{
        def set_ahoy_visit
          self.#{name} ||= Ahoy.instance.try(:visit_or_create)
        end
      }
    end
  end
end
