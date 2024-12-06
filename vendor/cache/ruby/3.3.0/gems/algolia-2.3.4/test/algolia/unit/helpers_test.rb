require 'algolia'
require 'test_helper'

class HelpersTest
  include Helpers

  describe 'test helpers' do
    def test_deserialize_settings
      old_settings = {
        attributesToIndex: %w(attr1 attr2),
        numericAttributesToIndex: %w(attr1 attr2),
        slaves: %w(index1 index2)
      }

      new_settings = {
        searchableAttributes: %w(attr1 attr2),
        numericAttributesForFiltering: %w(attr1 attr2),
        replicas: %w(index1 index2)
      }

      deserialized_settings = deserialize_settings(old_settings, true)
      assert_equal new_settings, deserialized_settings
    end

    def test_deserialize_settings_with_string
      old_settings = {
        'attributesToIndex' => %w(attr1 attr2),
        'numericAttributesToIndex' => %w(attr1 attr2),
        'slaves' => %w(index1 index2),
        'minWordSizefor1Typo' => 1
      }

      new_settings = {
        'searchableAttributes' => %w(attr1 attr2),
        'numericAttributesForFiltering' => %w(attr1 attr2),
        'replicas' => %w(index1 index2),
        'minWordSizefor1Typo' => 1
      }

      deserialized_settings = deserialize_settings(old_settings, false)
      assert_equal new_settings, deserialized_settings
    end

    def test_path_encode
      assert_equal path_encode('/1/indexes/%s/settings', 'premium+ some_name'), '/1/indexes/premium%2B+some_name/settings'
    end
  end

  describe 'test hash_includes_subset' do
    def test_empty_hashes
      h      = {}
      subset = {}
      assert hash_includes_subset?(h, subset)
    end

    def test_with_empty_subset
      h      = { a: 100, b: 200 }
      subset = {}
      assert hash_includes_subset?(h, subset)
    end

    def test_subset_included
      h      = { a: 100, b: 200 }
      subset = { a: 100 }
      assert hash_includes_subset?(h, subset)
    end

    def test_subset_not_included
      h      = { a: 100, b: 200 }
      subset = { c: 300 }
      refute hash_includes_subset?(h, subset)
    end

    def test_subset_included_but_wrong_value
      h      = { a: 100, b: 200 }
      subset = { a: 200 }
      refute hash_includes_subset?(h, subset)
    end

    def test_subset_included_with_multiple_values
      h      = { a: 100, b: 200, c: 300 }
      subset = { a: 100, b: 200 }
      assert hash_includes_subset?(h, subset)
    end

    def test_subset_not_included_because_too_many_values
      h      = { a: 100, b: 200 }
      subset = { a: 100, b: 200, c: 300 }
      refute hash_includes_subset?(h, subset)
    end
  end
end
