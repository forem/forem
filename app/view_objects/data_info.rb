# Throughout Forem, we encode JSON information in our Ruby templates.
# By convention, we often have a data-info attribute that is a Hash.
#
# This module provides some much needed character escaping to ensure
# that our JS that parses the data-info attribute doesn't choke.
#
# @see ./app/javascript/packs/followButtons.js for parsing
module DataInfo
  # A convenience method to ensure properly escape JSON data attributes.
  #
  # @param object [#class, #id, #name] responds to `#class`, `#id`,
  #        and `#name`, though you can "cheat" and pass the specific
  #        values to allow for over-riding (or when you have not quite
  #        well formed objects; looking at ArticleDecorator's
  #        cached_user.  It's not quite a valid object.)
  # @param id [String, Integer]
  # @param class_name [String]
  # @param name [String]
  # @param kwargs [Hash] any additional attributes to include in the
  #        JSON object.  In some cases we include a "style" attribute.
  #
  # @return [String] JSON formatted string.
  #
  # @example
  #   > DataInfo.to_json(object: User.first, name: "Duane \"The Rock\" Johnson", id: 1, style: "full")
  #   => "{\"user_id\":1,\"className\":\"User\",\"style\":\"full\",\"name\":\"Duane \\\"The Rock\\\" Johnson\"}"
  def self.to_json(object:, id: object.id, class_name: object.class_name, name: object.name, **kwargs)
    kwargs.merge(
      {
        id: id,
        className: class_name,
        name: name
      },
    ).to_json
  end
end
