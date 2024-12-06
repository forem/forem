require "spec_helper"
require "rolify/shared_examples/shared_examples_for_roles"
require "rolify/shared_examples/shared_examples_for_dynamic"
require "rolify/shared_examples/shared_examples_for_scopes"
require "rolify/shared_examples/shared_examples_for_callbacks"

describe "Using Rolify with custom User and Role class names" do
  def user_class
    Customer
  end

  def role_class
    Privilege
  end
  
  it_behaves_like Rolify::Role
  it_behaves_like "Role.scopes"
  it_behaves_like Rolify::Dynamic
  it_behaves_like "Rolify.callbacks"
end
