module ActsAsTaggableOn
  class Tag
    after_commit on: :create do
      ::Tag.find(id).index_to_elasticsearch
    end
  end
end
