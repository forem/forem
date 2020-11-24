require 'spec_helper'

module Ransack
  describe Translate do

    describe '.attribute' do
      it 'translate namespaced attribute like AR does' do
        ar_translation = ::Namespace::Article.human_attribute_name(:title)
        ransack_translation = Ransack::Translate.attribute(
          :title,
          :context => ::Namespace::Article.ransack.context
          )
        expect(ransack_translation).to eq ar_translation
      end
    end
  end
end
