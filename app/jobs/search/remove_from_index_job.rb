module Search
  class RemoveFromIndexJob < ApplicationJob
    queue_as :remove_from_algolia_index

    def perform(index, key)
      Algolia::Index.new(index).delete_object(key)
    end
  end
end
