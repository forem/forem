require "spec_helper"

describe Rolify do

  context 'cache' do
    let(:user) { User.first }
    before { user.grant(:zombie) }
    specify do
      expect(user).to have_role(:zombie)
      user.remove_role(:zombie)
      expect(user).to_not have_role(:zombie)
    end
  end
end
