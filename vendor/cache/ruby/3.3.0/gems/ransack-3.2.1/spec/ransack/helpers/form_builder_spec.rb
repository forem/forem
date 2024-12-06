require 'spec_helper'

module Ransack
  module Helpers
    describe FormBuilder do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people, :comments, :notes
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval { include router.url_helpers }
        @controller.view_context_class.class_eval { include router.url_helpers }
        @s = Person.ransack
        @controller.view_context.search_form_for(@s) { |f| @f = f }
      end

      it 'selects previously-entered time values with datetime_select' do
        date_values = %w(2011 1 2 03 04 05)
      # @s.created_at_eq = date_values # This works in Rails 4.x but not 3.x
        @s.created_at_eq = [2011, 1, 2, 3, 4, 5] # so we have to do this
        html = @f.datetime_select(
          :created_at_eq, :use_month_numbers => true, :include_seconds => true
          )
        date_values.each { |val| expect(html).to include date_select_html(val) }
      end

      describe '#label' do
        context 'with direct model attributes' do
          it 'localizes attribute names' do
            test_label(@f, :name_cont, /Full Name contains/)
            test_label(@f, :only_admin_start, /admin uSer Only starts with/)
            test_label(@f, :salary_gt, /wages greater than/)
            test_label(@f, :awesome_true, /ransack is really awesome is true/)
          end
          it 'falls back to `attribute_name.capitalize` when no translation' do
            test_label(@f, :email_cont, /Email contains/)
            test_label(@f, :only_sort_start, /Only sort starts with/)
            test_label(@f, :only_search_eq, /Only search equals/)
          end
        end
        context 'with `has_many` association attributes' do
          it 'localizes :"#{pluralized model}_#{attribute name}_#{predicate}"' do
            test_label(@f, :articles_body_start, /Article maiN BoDy starts with/)
          end
          it 'falls back to `model_name.capitalize + attribute_name.capitalize` when no translation' do
            test_label(@f, :articles_title_cont, /Article Title contains/)
            test_label(@f, :articles_subject_header_start, /Article Subject header starts with/)
          end
        end
        context 'with `belongs_to` association attributes' do
          before do
            @controller.view_context.search_form_for(Comment.ransack) { |f| @f = f }
          end
          it 'localizes :"#{singularized model}_#{attribute name}_#{predicate}"' do
            test_label(@f, :article_body_start, /Article maiN BoDy starts with/)
          end
          it 'falls back to `model_name.capitalize + attribute_name.capitalize` when no translation' do
            test_label(@f, :article_title_eq, /Article Title equals/)
            test_label(@f, :article_subject_header_end, /Article Subject header ends with/)
          end
        end
      end

      describe '#sort_link' do
        it 'sort_link for ransack attribute' do
          sort_link = @f.sort_link :name, :controller => 'people'
          expect(sort_link).to match /people\?q(%5B|\[)s(%5D|\])=name\+asc/
          expect(sort_link).to match /sort_link/
          expect(sort_link).to match /Full Name<\/a>/
        end
        it 'sort_link for common attribute' do
          sort_link = @f.sort_link :id, :controller => 'people'
          expect(sort_link).to match /id<\/a>/
        end
      end

      describe '#submit' do
        it 'localizes :search when no default value given' do
          html = @f.submit
          expect(html).to match /"Search"/
        end
      end

      describe '#attribute_select' do
        it 'returns ransackable attributes' do
          html = @f.attribute_select
          expect(html.split(/\n/).size).to eq(Person.ransackable_attributes.size + 1)
          Person.ransackable_attributes.each do |attribute|
            expect(html).to match /<option value="#{attribute}">/
          end
        end
        it 'returns ransackable attributes for associations with :associations' do
          attributes = Person.ransackable_attributes +
            Article.ransackable_attributes.map { |a| "articles_#{a}" }
          html = @f.attribute_select(:associations => ['articles'])
          expect(html.split(/\n/).size).to eq(attributes.size)
          attributes.each do |attribute|
            expect(html).to match /<option value="#{attribute}">/
          end
        end
        it 'returns option groups for base and associations with :associations' do
          html = @f.attribute_select(:associations => ['articles'])
          [Person, Article].each do |model|
            expect(html).to match /<optgroup label="#{model}">/
          end
        end
      end

      describe '#predicate_select' do
        it 'returns predicates with predicate_select' do
          html = @f.predicate_select
          Predicate.names.each do |key|
            expect(html).to match /<option value="#{key}">/
          end
        end
        it 'filters predicates with single-value :only' do
          html = @f.predicate_select :only => 'eq'
          Predicate.names.reject { |k| k =~ /^eq/ }.each do |key|
            expect(html).not_to match /<option value="#{key}">/
          end
        end
        it 'filters predicates with multi-value :only' do
          html = @f.predicate_select :only => [:eq, :lt]
          Predicate.names.reject { |k| k =~ /^(eq|lt)/ }.each do |key|
            expect(html).not_to match /<option value="#{key}">/
          end
        end
        it 'excludes compounds when compounds: false' do
          html = @f.predicate_select :compounds => false
          Predicate.names.select { |k| k =~ /_(any|all)$/ }.each do |key|
            expect(html).not_to match /<option value="#{key}">/
          end
        end
      end

      context 'fields used in polymorphic relations as search attributes in form' do
        before do
          @controller.view_context.search_form_for(Note.ransack) { |f| @f = f }
        end
        it 'accepts poly_id field' do
          html = @f.text_field(:notable_id_eq)
          expect(html).to match /id=\"q_notable_id_eq\"/
        end
        it 'accepts poly_type field' do
          html = @f.text_field(:notable_type_eq)
          expect(html).to match /id=\"q_notable_type_eq\"/
        end
      end

      private

        def test_label(f, query, expected)
          expect(f.label query).to match expected
        end

        # Starting from Rails 4.2, the date_select html attributes are no longer
        # `sort`ed (for a speed gain), so the tests have to be different:
        def date_select_html(val)
          %(<option value="#{val}" selected="selected">#{val}</option>)
        end

    end
  end
end
