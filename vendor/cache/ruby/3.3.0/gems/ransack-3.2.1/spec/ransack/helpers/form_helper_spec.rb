require 'spec_helper'

module Ransack
  module Helpers
    describe FormHelper do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people, :notes
        namespace :admin do
          resources :comments
        end
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval { include router.url_helpers }
        @controller.view_context_class.class_eval { include router.url_helpers }
      end

      describe '#sort_link with default search_key' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=name\+asc/ }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with default search_key' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=name\+asc/ }
      end

      describe '#sort_link with default search_key defined as symbol' do
        subject { @controller.view_context
          .sort_link(
            Person.ransack({ sorts: ['name desc'] }, search_key: :people_search),
            :name, controller: 'people'
          )
        }
        it { should match /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/ }
      end

      describe '#sort_url with default search_key defined as symbol' do
        subject { @controller.view_context
          .sort_url(
            Person.ransack({ sorts: ['name desc'] }, search_key: :people_search),
            :name, controller: 'people'
          )
        }
        it { should match /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/ }
      end

      describe '#sort_link desc through association table defined as symbol' do
        subject { @controller.view_context
          .sort_link(
            Person.ransack({ sorts: 'comments_body asc' }),
            :comments_body,
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=comments.body\+desc/ }
        it { should match /sort_link asc/ }
        it { should match /Body&nbsp;&#9650;/ }
      end

      describe '#sort_url desc through association table defined as symbol' do
        subject { @controller.view_context
          .sort_url(
            Person.ransack({ sorts: 'comments_body asc' }),
            :comments_body,
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=comments.body\+desc/ }
      end

      describe '#sort_link through association table defined as a string' do
        subject { @controller.view_context
          .sort_link(
            Person.ransack({ sorts: 'comments.body desc' }),
            'comments.body',
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=comments.body\+asc/ }
        it { should match /sort_link desc/ }
        it { should match /Comments.body&nbsp;&#9660;/ }
      end

      describe '#sort_url through association table defined as a string' do
        subject { @controller.view_context
          .sort_url(
            Person.ransack({ sorts: 'comments.body desc' }),
            'comments.body',
            controller: 'people'
          )
        }
        it { should match /people\?q(%5B|\[)s(%5D|\])=comments.body\+asc/ }
      end

      describe '#sort_link works even if search params are a blank string' do
        before { @controller.view_context.params[:q] = '' }
        specify {
          expect { @controller.view_context
            .sort_link(
              Person.ransack(@controller.view_context.params[:q]),
              :name,
              controller: 'people'
            )
          }.not_to raise_error
        }
      end

      describe '#sort_url works even if search params are a blank string' do
        before { @controller.view_context.params[:q] = '' }
        specify {
          expect { @controller.view_context
            .sort_url(
              Person.ransack(@controller.view_context.params[:q]),
              :name,
              controller: 'people'
            )
          }.not_to raise_error
        }
      end

      describe '#sort_link with search_key defined as a string' do
        subject { @controller.view_context
          .sort_link(
            Person.ransack(
              { sorts: ['name desc'] }, search_key: 'people_search'
            ),
            :name,
            controller: 'people'
          )
        }
        it { should match /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/ }
      end

      describe '#sort_link with default_order defined with a string key' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack()],
            :name,
            controller: 'people',
            default_order: 'desc'
          )
        }
        it { should_not match /default_order/ }
      end

      describe '#sort_url with default_order defined with a string key' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack()],
            :name,
            controller: 'people',
            default_order: 'desc'
          )
        }
        it { should_not match /default_order/ }
      end

      describe '#sort_link with multiple search_keys defined as an array' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys defined as an array' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys does not break on nil values & ignores them' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc', nil, 'email', nil])],
            :name, [nil, :name, nil, 'email DESC', nil],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys does not break on nil values & ignores them' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack(sorts: ['name desc', nil, 'email', nil])],
            :name, [nil, :name, nil, 'email DESC', nil],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys should allow a label to be specified' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            'Property Name',
            controller: 'people'
          )
        }
        it { should match /Property Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with multiple search_keys should flip multiple fields specified without a direction' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc', 'email asc'])],
            :name, [:name, :email],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys should flip multiple fields specified without a direction' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack(sorts: ['name desc', 'email asc'])],
            :name, [:name, :email],
            controller: 'people'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys and default_order specified as a string' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack()],
            :name, [:name, :email],
            controller: 'people',
            default_order: 'desc'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys and default_order specified as a string' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack()],
            :name, [:name, :email],
            controller: 'people',
            default_order: 'desc'
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys and default_order specified as a symbol' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack()],
            :name, [:name, :email],
            controller: 'people',
            default_order: :desc
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys and default_order specified as a symbol' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack],
            :name, [:name, :email],
            controller: 'people',
            default_order: :desc
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys should allow multiple default_orders to be specified' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack],
            :name, [:name, :email],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+asc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys should allow multiple default_orders to be specified' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack],
            :name, [:name, :email],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+asc/
          )
        }
      end

      describe '#sort_link with multiple search_keys with multiple default_orders should not override a specified order' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack],
            :name, [:name, 'email desc'],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys with multiple default_orders should not override a specified order' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.ransack],
            :name, [:name, 'email desc'],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(/people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe "#sort_link on polymorphic association should preserve association model name case" do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Note.ransack],
            :notable_of_Person_type_name, "Notable",
            controller: 'notes'
          )
        }
        it { should match /notes\?q(%5B|\[)s(%5D|\])=notable_of_Person_type_name\+asc/ }
        it { should match /sort_link/ }
        it { should match /Notable/ }
      end

      describe "#sort_url on polymorphic association should preserve association model name case" do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Note.ransack],
            :notable_of_Person_type_name, "Notable",
            controller: 'notes'
          )
        }
        it { should match /notes\?q(%5B|\[)s(%5D|\])=notable_of_Person_type_name\+asc/ }
      end

      context 'view has existing parameters' do

        describe '#sort_link should not remove existing params' do

          before { @controller.view_context.params[:exist] = 'existing' }

          subject {
            @controller.view_context.sort_link(
              Person.ransack(
                { sorts: ['name desc'] },
                search_key: 'people_search'
              ),
              :name,
              controller: 'people'
            )
          }

          it { should match /exist\=existing/ }
        end

        describe '#sort_url should not remove existing params' do

          before { @controller.view_context.params[:exist] = 'existing' }

          subject {
            @controller.view_context.sort_url(
              Person.ransack(
                { sorts: ['name desc'] },
                search_key: 'people_search'
              ),
              :name,
              controller: 'people'
            )
          }

          it { should match /exist\=existing/ }
        end

        context 'using a real ActionController::Parameter object' do

          describe 'with symbol q:, #sort_link should include search params' do
            subject { @controller.view_context.sort_link(Person.ransack, :name) }
            let(:params) { ActionController::Parameters.new(
              { :q => { name_eq: 'TEST' }, controller: 'people' }
              ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=TEST&amp;q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe 'with symbol q:, #sort_url should include search params' do
            subject { @controller.view_context.sort_url(Person.ransack, :name) }
            let(:params) { ActionController::Parameters.new(
              { :q => { name_eq: 'TEST' }, controller: 'people' }
              ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=TEST&q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe "with string 'q', #sort_link should include search params" do
            subject { @controller.view_context.sort_link(Person.ransack, :name) }
            let(:params) {
              ActionController::Parameters.new(
                { 'q' => { name_eq: 'Test2' }, controller: 'people' }
                ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=Test2&amp;q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe "with string 'q', #sort_url should include search params" do
            subject { @controller.view_context.sort_url(Person.ransack, :name) }
            let(:params) {
              ActionController::Parameters.new(
                { 'q' => { name_eq: 'Test2' }, controller: 'people' }
                ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=Test2&q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end
        end
      end

      describe '#sort_link with hide order indicator set to true' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: true
          )
        }
        it { should match /Full Name/ }
        it { should_not match /&#9660;|&#9650;/ }
      end

      describe '#sort_link with hide order indicator set to false' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with config set with custom up_arrow' do
        before do
          Ransack.configure { |c| c.custom_arrows = { up_arrow: "\u{1F446}" } }
        end

        after do
          Ransack.configure { |c| c.custom_arrows = { up_arrow: "&#9660;" } }
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }

        it { should match /Full Name&nbsp;\u{1F446}/ }
      end

      describe '#sort_link with config set with custom down_arrow' do
        before do
          Ransack.configure { |c| c.custom_arrows = { down_arrow: "\u{1F447}" } }
        end

        after do
          Ransack.configure { |c| c.custom_arrows = { down_arrow: "&#9650;" } }
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name asc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }

        it { should match /Full Name&nbsp;\u{1F447}/ }
      end

      describe '#sort_link with config set to hide arrows' do
        before do
          Ransack.configure { |c| c.hide_sort_order_indicators = true }
        end

        after do
          Ransack.configure { |c| c.hide_sort_order_indicators = false }
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }

        it { should_not match /&#9660;|&#9650;/ }
      end

      describe '#sort_link with config set to show arrows (default setting)' do
        before do
          Ransack.configure { |c| c.hide_sort_order_indicators = false }
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }

        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with config set to show arrows and a default arrow set' do
        before do
          Ransack.configure do |c|
            c.hide_sort_order_indicators = false
            c.custom_arrows = { default_arrow: "defaultarrow" }
          end
        end

        after do
          Ransack.configure do |c|
            c.custom_arrows = { default_arrow: nil }
          end
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack],
            :name,
            controller: 'people'
          )
        }

        it { should match /Full Name&nbsp;defaultarrow/ }
      end

      describe '#sort_link w/config to hide arrows + custom arrow, hides all' do
        before do
          Ransack.configure do |c|
            c.hide_sort_order_indicators = true
            c.custom_arrows = { down_arrow: 'down', default_arrow: "defaultarrow" }
          end
        end

        after do
          Ransack.configure do |c|
            c.hide_sort_order_indicators = false
            c.custom_arrows = { down_arrow: '&#9650;' }
          end
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }

        it { should_not match /&#9660;|down|defaultarrow/ }
      end

      describe '#sort_link with config set to show arrows + custom arrow' do
        before do
          Ransack.configure do |c|
            c.hide_sort_order_indicators = false
            c.custom_arrows = { up_arrow: 'up-value' }
          end
        end

        after do
          Ransack.configure do |c|
            c.hide_sort_order_indicators = false
            c.custom_arrows = { up_arrow: '&#9660;' }
          end
        end

        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }

        it { should match /&#9650;|up-value/ }
      end

      describe '#sort_link with a block' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            controller: 'people'
          ) { 'Block label' }
        }
        it { should match /Block label&nbsp;&#9660;/ }
      end

      describe '#sort_link with class option' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            class: 'people', controller: 'people'
          )
        }
        it { should match /class="sort_link desc people"/ }
        it { should_not match /people\?class=people/ }
      end

      describe '#sort_link with class option workaround' do
        it "generates a correct link and prints a deprecation" do
          expect do
            link = @controller.view_context
              .sort_link(
                [:main_app, Person.ransack(sorts: ['name desc'])],
                :name,
                'name',
                { controller: 'people' },
                class: 'people'
              )

            expect(link).to match(/class="sort_link desc people"/)
            expect(link).not_to match(/people\?class=people/)
          end.to output(
            /Passing two trailing hashes to `sort_link` is deprecated, merge the trailing hashes into a single one\. \(called at #{Regexp.escape(__FILE__)}:/
          ).to_stderr
        end
      end

      describe '#sort_link with data option' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            data: { turbo_action: :advance }, controller: 'people'
          )
        }
        it { should match /data-turbo-action="advance"/ }
        it { should_not match /people\?data%5Bturbo_action%5D=advance/ }
      end

      describe "#sort_link with host option" do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.ransack(sorts: ['name desc'])],
            :name,
            host: 'foo', controller: 'people'
          )
        }
        it { should match /href="\/people\?q/ }
        it { should_not match /href=".*foo/ }
      end

      describe '#search_form_for with default format' do
        subject { @controller.view_context
          .search_form_for(Person.ransack) {} }
        it { should match /action="\/people"/ }
      end

      describe '#search_form_for with pdf format' do
        subject {
          @controller.view_context
          .search_form_for(Person.ransack, format: :pdf) {}
        }
        it { should match /action="\/people.pdf"/ }
      end

      describe '#search_form_for with json format' do
        subject {
          @controller.view_context
          .search_form_for(Person.ransack, format: :json) {}
        }
        it { should match /action="\/people.json"/ }
      end

      describe '#search_form_for with an array of routes' do
        subject {
          @controller.view_context
          .search_form_for([:admin, Comment.ransack]) {}
        }
        it { should match /action="\/admin\/comments"/ }
      end

      describe '#search_form_for with custom default search key' do
        before do
          Ransack.configure { |c| c.search_key = :example }
        end
        subject {
          @controller.view_context
          .search_form_for(Person.ransack) { |f| f.text_field :name_eq }
        }
        it { should match /example_name_eq/ }
      end
    end
  end
end
