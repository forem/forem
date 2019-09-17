module Search
  class RemoveFromIndexJob < ApplicationJob
    queue_as :search_remove_from_index

    def perform(index, key)
      Algolia::Index.new(index).delete_object(key)
    end
  end
end
