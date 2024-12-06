require "spec_helper"
require "rolify/shared_examples/shared_examples_for_roles"
require "rolify/shared_examples/shared_examples_for_dynamic"
require "rolify/shared_examples/shared_examples_for_scopes"
require "rolify/shared_examples/shared_examples_for_callbacks"

describe "Rolify.namespace" do
  def user_class
    Admin::Moderator
  end

  def role_class
    Admin::Right
  end
  
  def join_table
    "moderators_rights"
  end
  
  it_behaves_like Rolify::Role
  it_behaves_like "Role.scopes"
  it_behaves_like Rolify::Dynamic
  it_behaves_like "Rolify.callbacks"
end
