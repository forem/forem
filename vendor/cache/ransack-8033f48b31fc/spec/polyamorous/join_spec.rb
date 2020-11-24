require 'spec_helper'

module Polyamorous
  describe Join do
    it 'is a tree node' do
      join = new_join(:articles, :outer)
      expect(join).to be_kind_of(TreeNode)
    end

    it 'can be added to a tree' do
      join = new_join(:articles, :outer)

      tree_hash = {}
      join.add_to_tree(tree_hash)

      expect(tree_hash[join]).to be {}
    end
  end
end
