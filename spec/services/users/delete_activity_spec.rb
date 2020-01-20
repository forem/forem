require "rails_helper"

RSpec.describe Users::DeleteActivity, type: :service do
  let(:user) { create(:user) }

  # rubocop:disable Rspec/ExampleLength
  it "destroys all associations" do
    user_associations = []
    # User.reflect_on_all_associations.each do |association|
    #   associated_object = association.create(user: user)
    #   associations.push associated_object
    # end
    # direct associations to be destroyed
    associations = User.reflect_on_all_associations.reject { |ass| ass.options.key?(:join_table) || ass.options.key?(:through) }
    kept_associations = [:created_podcasts]
    associations.reject { |a| kept_associations.include?(a.name) }.sort_by(&:name).each do |ass|
      # p ass.name
      # p ass.options
      if user.public_send(ass.name).present?
        # p " exists"
        user_associations.push(*user.public_send(ass.name))
      else
        singular_name = ActiveSupport::Inflector.singularize(ass.name)
        factory_name = ass.options[:class_name] || singular_name
        possible_factory_name = factory_name.underscore.tr("/", "_")
        inverse_of = ass.options[:inverse_of] || ass.options[:as] || :user
        # p "create(#{possible_factory_name}, #{inverse_of} => #{user})"
        record = create(possible_factory_name, inverse_of => user)
        # p record.id
        user_associations.push record
        # p "---------------"
        # user.public_send(ass.name).create(attributes_for(factory_name))
        # association = create(ass_name, user: user)
        # associations.push associated_object
      end
    end
    user.reload
    # p user_associations.map{ |a| a.class.name }
    Users::Delete.call(user)
    user_associations.each do |ass|
      p ass.class.name
      # if ass.class.name == "Doorkeeper::AccessGrant"
      #   binding.pry
      # end
      expect { ass.reload }.to raise_error(ActiveRecord::RecordNotFound)
      # expect(ass.destroyed?).to be true # ну как-то проверить, что удалён
    end
  end
  # rubocop:enable Rspec/ExampleLength
end
