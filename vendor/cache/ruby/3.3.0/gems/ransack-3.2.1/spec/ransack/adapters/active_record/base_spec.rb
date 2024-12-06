require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Base do

        subject { ::ActiveRecord::Base }

        it { should respond_to :ransack }

        describe '#search' do
          subject { Person.ransack }

          it { should be_a Search }
          it 'has a Relation as its object' do
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end

          context "multiple database connection" do
            it "does not raise error" do
              expect { Person.ransack(name_cont: "test") }.not_to raise_error
              expect { SubDB::OperationHistory.ransack(people_id_eq: 1) }.not_to raise_error
            end
          end

          context 'with scopes' do
            before do
              allow(Person)
              .to receive(:ransackable_scopes)
              .and_return([:active, :over_age, :of_age])
            end

            it 'applies true scopes' do
              s = Person.ransack('active' => true)
              expect(s.result.to_sql).to (include 'active = 1')
            end

            it 'applies stringy true scopes' do
              s = Person.ransack('active' => 'true')
              expect(s.result.to_sql).to (include 'active = 1')
            end

            it 'applies stringy boolean scopes with true value in an array' do
              s = Person.ransack('of_age' => ['true'])
              expect(s.result.to_sql).to (include rails7_and_mysql ? %q{(age >= '18')} : 'age >= 18')
            end

            it 'applies stringy boolean scopes with false value in an array' do
              s = Person.ransack('of_age' => ['false'])
              expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age < '18'} : 'age < 18')
            end

            it 'ignores unlisted scopes' do
              s = Person.ransack('restricted' => true)
              expect(s.result.to_sql).to_not (include 'restricted')
            end

            it 'ignores false scopes' do
              s = Person.ransack('active' => false)
              expect(s.result.to_sql).not_to (include 'active')
            end

            it 'ignores stringy false scopes' do
              s = Person.ransack('active' => 'false')
              expect(s.result.to_sql).to_not (include 'active')
            end

            it 'passes values to scopes' do
              s = Person.ransack('over_age' => 18)
              expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age > '18'} : 'age > 18')
            end

            it 'chains scopes' do
              s = Person.ransack('over_age' => 18, 'active' => true)
              expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age > '18'} : 'age > 18')
              expect(s.result.to_sql).to (include 'active = 1')
            end

            it 'applies scopes that define string SQL joins' do
              allow(Article)
                .to receive(:ransackable_scopes)
                .and_return([:latest_comment_cont])

              # Including a negative condition to test removing the scope
              s = Search.new(Article, notes_note_not_eq: 'Test', latest_comment_cont: 'Test')
              expect(s.result.to_sql).to include 'latest_comment'
            end

            context "with sanitize_custom_scope_booleans set to false" do
              before(:all) do
                Ransack.configure { |c| c.sanitize_custom_scope_booleans = false }
              end

              after(:all) do
                Ransack.configure { |c| c.sanitize_custom_scope_booleans = true }
              end

              it 'passes true values to scopes' do
                s = Person.ransack('over_age' => 1)
                expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age > '1'} : 'age > 1')
              end

              it 'passes false values to scopes'  do
                s = Person.ransack('over_age' => 0)
                expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age > '0'} : 'age > 0')
              end
            end

            context "with ransackable_scopes_skip_sanitize_args enabled for scope" do
              before do
                allow(Person)
                .to receive(:ransackable_scopes_skip_sanitize_args)
                .and_return([:over_age])
              end

              it 'passes true values to scopes' do
                s = Person.ransack('over_age' => 1)
                expect(s.result.to_sql).to (include rails7_and_mysql ? %q{age > '1'} : 'age > 1')
              end

              it 'passes false values to scopes'  do
                s = Person.ransack('over_age' => 0)
                expect(s.result.to_sql).to (include  rails7_and_mysql ? %q{age > '0'} : 'age > 0')
              end
            end

          end

          it 'does not raise exception for string :params argument' do
            expect { Person.ransack('') }.to_not raise_error
          end

          it 'raises exception if ransack! called with unknown condition' do
            expect { Person.ransack!(unknown_attr_eq: 'Ernie') }.to raise_error(ArgumentError)
          end

          it 'does not modify the parameters' do
            params = { name_eq: '' }
            expect { Person.ransack(params) }.not_to change { params }
          end
        end

        context 'negative conditions on HABTM associations' do
          let(:medieval) { Tag.create!(name: 'Medieval') }
          let(:fantasy)  { Tag.create!(name: 'Fantasy') }
          let(:arthur)   { Article.create!(title: 'King Arthur') }
          let(:marco)    { Article.create!(title: 'Marco Polo') }

          before do
            marco.tags << medieval
            arthur.tags << medieval
            arthur.tags << fantasy
          end

          it 'removes redundant joins from top query' do
            s = Article.ransack(tags_name_not_eq: "Fantasy")
            sql = s.result.to_sql
            expect(sql).to_not include('LEFT OUTER JOIN')
          end

          it 'handles != for single values' do
            s = Article.ransack(tags_name_not_eq: "Fantasy")
            articles = s.result.to_a
            expect(articles).to include marco
            expect(articles).to_not include arthur
          end

          it 'handles NOT IN for multiple attributes' do
            s = Article.ransack(tags_name_not_in: ["Fantasy", "Scifi"])
            articles = s.result.to_a

            expect(articles).to include marco
            expect(articles).to_not include arthur
          end
        end

        context 'negative conditions on self-referenced associations' do
          let(:pop) { Person.create!(name: 'Grandpa') }
          let(:dad) { Person.create!(name: 'Father') }
          let(:mom) { Person.create!(name: 'Mother') }
          let(:son) { Person.create!(name: 'Grandchild') }

          before do
            son.parent = dad
            dad.parent = pop
            dad.children << son
            mom.children << son
            pop.children << dad
            son.save! && dad.save! && mom.save! && pop.save!
          end

          it 'handles multiple associations and aliases' do
            s = Person.ransack(
              c: {
                '0' => { a: ['name'], p: 'not_eq', v: ['Father'] },
                '1' => {
                        a: ['children_name', 'parent_name'],
                        p: 'not_eq', v: ['Father'], m: 'or'
                      },
                '2' => { a: ['children_salary'], p: 'eq', v: [nil] }
              })
            people = s.result

            expect(people.to_a).to include son
            expect(people.to_a).to include mom
            expect(people.to_a).to_not include dad  # rule '0': 'name'
            expect(people.to_a).to_not include pop  # rule '1': 'children_name'
          end
        end

        describe '#ransack_alias' do
          it 'translates an alias to the correct attributes' do
            p = Person.create!(name: 'Meatloaf', email: 'babies@example.com')

            s = Person.ransack(term_cont: 'atlo')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(term_cont: 'babi')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(term_cont: 'nomatch')
            expect(s.result.to_a).to eq []
          end

          it 'also works with associations' do
            dad = Person.create!(name: 'Birdman')
            son = Person.create!(name: 'Weezy', parent: dad)

            s = Person.ransack(daddy_eq: 'Birdman')
            expect(s.result.to_a).to eq [son]

            s = Person.ransack(daddy_eq: 'Drake')
            expect(s.result.to_a).to eq []
          end

          it 'makes aliases available to subclasses' do
            yngwie = Musician.create!(name: 'Yngwie Malmsteen')

            musicians = Musician.ransack(term_cont: 'ngw').result
            expect(musicians).to eq([yngwie])
          end

          it 'handles naming collisions gracefully' do
            frank = Person.create!(name: 'Frank Stallone')

            people = Person.ransack(term_cont: 'allon').result
            expect(people).to eq([frank])

            Class.new(Article) do
              ransack_alias :term, :title
            end

            people = Person.ransack(term_cont: 'allon').result
            expect(people).to eq([frank])
          end
        end

        describe '#ransacker' do
          # For infix tests
          def self.sane_adapter?
            case ::ActiveRecord::Base.connection.adapter_name
            when 'SQLite3', 'PostgreSQL'
              true
            else
              false
            end
          end
          # in schema.rb, class Person:
          # ransacker :reversed_name, formatter: proc { |v| v.reverse } do |parent|
          #   parent.table[:name]
          # end
          #
          # ransacker :doubled_name do |parent|
          #   Arel::Nodes::InfixOperation.new(
          #     '||', parent.table[:name], parent.table[:name]
          #   )
          # end

          it 'creates ransack attributes' do
            person = Person.create!(name: 'Aric Smith')

            s = Person.ransack(reversed_name_eq: 'htimS cirA')
            expect(s.result.size).to eq(1)

            expect(s.result.first).to eq person
          end

          it 'can be accessed through associations' do
            s = Person.ransack(children_reversed_name_eq: 'htimS cirA')
            expect(s.result.to_sql).to match(
              /#{quote_table_name("children_people")}.#{
                 quote_column_name("name")} = 'Aric Smith'/
            )
          end

          it 'allows an attribute to be an InfixOperation' do
            s = Person.ransack(doubled_name_eq: 'Aric SmithAric Smith')
            expect(s.result.first).to eq Person.where(name: 'Aric Smith').first
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it 'does not break #count if using InfixOperations' do
            s = Person.ransack(doubled_name_eq: 'Aric SmithAric Smith')
            expect(s.result.count).to eq 1
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it 'should remove empty key value pairs from the params hash' do
            s = Person.ransack(children_reversed_name_eq: '')
            expect(s.result.to_sql).not_to match /LEFT OUTER JOIN/
          end

          it 'should keep proper key value pairs in the params hash' do
            s = Person.ransack(children_reversed_name_eq: 'Testing')
            expect(s.result.to_sql).to match /LEFT OUTER JOIN/
          end

          it 'should function correctly when nil is passed in' do
            s = Person.ransack(nil)
          end

          it 'should function correctly when a blank string is passed in' do
            s = Person.ransack('')
          end

          it 'should function correctly with a multi-parameter attribute' do
            if ::ActiveRecord::VERSION::MAJOR >= 7
              ::ActiveRecord.default_timezone = :utc
            else
              ::ActiveRecord::Base.default_timezone = :utc
            end
            Time.zone = 'UTC'

            date = Date.current
            s = Person.ransack(
              { 'created_at_gteq(1i)' => date.year,
                'created_at_gteq(2i)' => date.month,
                'created_at_gteq(3i)' => date.day
              }
            )
            expect(s.result.to_sql).to match />=/
            expect(s.result.to_sql).to match date.to_s
          end

          it 'should function correctly when using fields with dots in them' do
            s = Person.ransack(email_cont: 'example.com')
            expect(s.result.exists?).to be true
          end

          it 'should function correctly when using fields with % in them' do
            p = Person.create!(name: '110%-er')
            s = Person.ransack(name_cont: '10%')
            expect(s.result.to_a).to eq [p]
          end

          it 'should function correctly when using fields with backslashes in them' do
            p = Person.create!(name: "\\WINNER\\")
            s = Person.ransack(name_cont: "\\WINNER\\")
            expect(s.result.to_a).to eq [p]
          end

          context 'searching by underscores' do
            # when escaping is supported right in LIKE expression without adding extra expressions
            def self.simple_escaping?
              case ::ActiveRecord::Base.connection.adapter_name
                when 'Mysql2', 'PostgreSQL'
                  true
                else
                  false
              end
            end

            it 'should search correctly if matches exist' do
              p = Person.create!(name: 'name_with_underscore')
              s = Person.ransack(name_cont: 'name_')
              expect(s.result.to_a).to eq [p]
            end if simple_escaping?

            it 'should return empty result if no matches' do
              Person.create!(name: 'name_with_underscore')
              s = Person.ransack(name_cont: 'n_')
              expect(s.result.to_a).to eq []
            end if simple_escaping?
          end

          context 'searching on an `in` predicate with a ransacker' do
            it 'should function correctly when passing an array of ids' do
              s = Person.ransack(array_people_ids_in: true)
              expect(s.result.count).to be > 0

              s = Person.ransack(array_where_people_ids_in: [1, '2', 3])
              expect(s.result.count).to be 3
              expect(s.result.map(&:id)).to eq [3, 2, 1]
            end

            it 'should function correctly when passing an array of strings' do
              a, b = Person.select(:id).order(:id).limit(2).map { |a| a.id.to_s }

              Person.create!(name: a)
              s = Person.ransack(array_people_names_in: true)
              expect(s.result.count).to be > 0
              s = Person.ransack(array_where_people_names_in: a)
              expect(s.result.count).to be 1

              Person.create!(name: b)
              s = Person.ransack(array_where_people_names_in: [a, b])
              expect(s.result.count).to be 2
            end

            it 'should function correctly with an Arel SqlLiteral' do
              s = Person.ransack(sql_literal_id_in: 1)
              expect(s.result.count).to be 1
              s = Person.ransack(sql_literal_id_in: ['2', 4, '5', 8])
              expect(s.result.count).to be 4
            end
          end

          context 'search on an `in` predicate with an array' do
            it 'should function correctly when passing an array of ids' do
              array = Person.all.map(&:id)
              s = Person.ransack(id_in: array)
              expect(s.result.count).to eq array.size
            end
          end

          it 'should work correctly when an attribute name ends with _start' do
            p = Person.create!(new_start: 'Bar and foo', name: 'Xiang')

            s = Person.ransack(new_start_end: ' and foo')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(name_or_new_start_start: 'Xia')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(new_start_or_name_end: 'iang')
            expect(s.result.to_a).to eq [p]
          end

          it 'should work correctly when an attribute name ends with _end' do
            p = Person.create!(stop_end: 'Foo and bar', name: 'Marianne')

            s = Person.ransack(stop_end_start: 'Foo and')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(stop_end_or_name_end: 'anne')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(name_or_stop_end_end: ' bar')
            expect(s.result.to_a).to eq [p]
          end

          it 'should work correctly when an attribute name has `and` in it' do
            p = Person.create!(terms_and_conditions: true)
            s = Person.ransack(terms_and_conditions_eq: true)
            expect(s.result.to_a).to eq [p]
          end

          context 'attribute aliased column names',
          if: Ransack::SUPPORTS_ATTRIBUTE_ALIAS do
            it 'should be translated to original column name' do
              s = Person.ransack(full_name_eq: 'Nicolas Cage')
              expect(s.result.to_sql).to match(
                /WHERE #{quote_table_name("people")}.#{quote_column_name("name")}/
              )
            end

            it 'should translate on associations' do
              s = Person.ransack(articles_content_cont: 'Nicolas Cage')
              expect(s.result.to_sql).to match(
                /#{quote_table_name("articles")}.#{
                   quote_column_name("body")} I?LIKE '%Nicolas Cage%'/
              )
            end
          end

          it 'sorts with different join variants' do
            comments = [
              Comment.create(article: Article.create(title: 'Avenger'), person: Person.create(salary: 100_000)),
              Comment.create(article: Article.create(title: 'Avenge'), person: Person.create(salary: 50_000)),
            ]
            expect(Comment.ransack(article_title_cont: 'aven', s: 'person_salary desc').result).to eq(comments)
            expect(Comment.joins(:person).ransack(s: 'persons_salarydesc', article_title_cont: 'aven').result).to eq(comments)
            expect(Comment.joins(:person).ransack(article_title_cont: 'aven', s: 'persons_salary desc').result).to eq(comments)
          end

          it 'allows sort by `only_sort` field' do
            s = Person.ransack(
              's' => { '0' => { 'dir' => 'asc', 'name' => 'only_sort' } }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} ASC/
            )
          end

          it 'does not sort by `only_search` field' do
            s = Person.ransack(
              's' => { '0' => { 'dir' => 'asc', 'name' => 'only_search' } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_search")} ASC/
            )
          end

          it 'allows search by `only_search` field' do
            s = Person.ransack(only_search_eq: 'htimS cirA')
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_search")} = 'htimS cirA'/
            )
          end

          it 'cannot be searched by `only_sort`' do
            s = Person.ransack(only_sort_eq: 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} = 'htimS cirA'/
            )
          end

          it 'allows sort by `only_admin` field, if auth_object: :admin' do
            s = Person.ransack(
              { 's' => { '0' => { 'dir' => 'asc', 'name' => 'only_admin' } } },
              { auth_object: :admin }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it 'does not sort by `only_admin` field, if auth_object: nil' do
            s = Person.ransack(
              's' => { '0' => { 'dir' => 'asc', 'name' => 'only_admin' } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it 'allows search by `only_admin` field, if auth_object: :admin' do
            s = Person.ransack(
              { only_admin_eq: 'htimS cirA' },
              { auth_object: :admin }
            )
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it 'cannot be searched by `only_admin`, if auth_object: nil' do
            s = Person.ransack(only_admin_eq: 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it 'should allow passing ransacker arguments to a ransacker' do
            s = Person.ransack(
              c: [{
                a: {
                  '0' => {
                    name: 'with_arguments', ransacker_args: [10, 100]
                  }
                },
                p: 'cont',
                v: ['Passing arguments to ransackers!']
              }]
            )
            expect(s.result.to_sql).to match(
              /LENGTH\(articles.body\) BETWEEN 10 AND 100/
            )
            expect(s.result.to_sql).to match(
              /LIKE \'\%Passing arguments to ransackers!\%\'/
              )
            expect { s.result.first }.to_not raise_error
          end

          it 'should allow sort passing arguments to a ransacker' do
            s = Person.ransack(
              s: {
                '0' => {
                  name: 'with_arguments', dir: 'desc', ransacker_args: [2, 6]
                }
              }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY \(SELECT MAX\(articles.title\) FROM articles/
              )
            expect(s.result.to_sql).to match(
              /WHERE articles.person_id = people.id AND LENGTH\(articles.body\)/
              )
            expect(s.result.to_sql).to match(
              /BETWEEN 2 AND 6 GROUP BY articles.person_id \) DESC/
            )
          end

          context 'case insensitive sorting' do
            it 'allows sort by desc' do
              search = Person.ransack(sorts: ['name_case_insensitive desc'])
              expect(search.result.to_sql).to match /ORDER BY LOWER(.*) DESC/
            end

            it 'allows sort by asc' do
              search = Person.ransack(sorts: ['name_case_insensitive asc'])
              expect(search.result.to_sql).to match /ORDER BY LOWER(.*) ASC/
            end
          end

          context 'regular sorting' do
            it 'allows sort by desc' do
              search = Person.ransack(sorts: ['name desc'])
              expect(search.result.to_sql).to match /ORDER BY .* DESC/
            end

            it 'allows sort by asc' do
              search = Person.ransack(sorts: ['name asc'])
              expect(search.result.to_sql).to match /ORDER BY .* ASC/
            end
          end

          context 'sorting by a scope' do
            it 'applies the correct scope' do
              search = Person.ransack(sorts: ['reverse_name asc'])
              expect(search.result.to_sql).to include("ORDER BY REVERSE(name) ASC")
            end
          end
        end

        describe '#ransackable_attributes' do
          context 'when auth_object is nil' do
            subject { Person.ransackable_attributes }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'term' }
            it { should include 'only_search' }
            it { should_not include 'only_sort' }
            it { should_not include 'only_admin' }

            if Ransack::SUPPORTS_ATTRIBUTE_ALIAS
              it { should include 'full_name' }
            end
          end

          context 'with auth_object :admin' do
            subject { Person.ransackable_attributes(:admin) }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_search' }
            it { should_not include 'only_sort' }
            it { should include 'only_admin' }
          end
        end

        describe '#ransortable_attributes' do
          context 'when auth_object is nil' do
            subject { Person.ransortable_attributes }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_sort' }
            it { should_not include 'only_search' }
            it { should_not include 'only_admin' }
          end

          context 'with auth_object :admin' do
            subject { Person.ransortable_attributes(:admin) }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_sort' }
            it { should_not include 'only_search' }
            it { should include 'only_admin' }
          end
        end

        describe '#ransackable_associations' do
          subject { Person.ransackable_associations }

          it { should include 'parent' }
          it { should include 'children' }
          it { should include 'articles' }
        end

        describe '#ransackable_scopes' do
          subject { Person.ransackable_scopes }

          it { should eq [] }
        end

        describe '#ransackable_scopes_skip_sanitize_args' do
          subject { Person.ransackable_scopes_skip_sanitize_args }

          it { should eq [] }
        end

        private
        def rails7_and_mysql
          ::ActiveRecord::VERSION::MAJOR >= 7 && ENV['DB'] == 'mysql'
        end
      end
    end
  end
end
