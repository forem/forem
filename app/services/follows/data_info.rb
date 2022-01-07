module Follows
  module DataInfo
    def self.to_json(object:, id: object.id, class_name: object.class.name, name: object.name, **kwargs)
      kwargs.merge(
        {
          id: id,
          className: class_name,
          name: name
        },
      ).to_json
    end
  end
end
