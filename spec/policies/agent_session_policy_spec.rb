require "rails_helper"

RSpec.describe AgentSessionPolicy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:normalized_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 1 }
    }
  end
  let(:agent_session) do
    AgentSession.create!(user: user, title: "Test", tool_name: "claude_code", normalized_data: normalized_data)
  end

  describe "#show?" do
    context "when session is published" do
      before { agent_session.update!(published: true) }

      it "allows nil user (public)" do
        policy = described_class.new(nil, agent_session)
        expect(policy.show?).to be true
      end

      it "allows random user" do
        policy = described_class.new(other_user, agent_session)
        expect(policy.show?).to be true
      end

      it "allows owner" do
        policy = described_class.new(user, agent_session)
        expect(policy.show?).to be true
      end

      it "allows admin" do
        policy = described_class.new(admin, agent_session)
        expect(policy.show?).to be true
      end
    end

    context "when session is unpublished" do
      it "raises UserRequiredError for nil user" do
        policy = described_class.new(nil, agent_session)
        expect { policy.show? }.to raise_error(ApplicationPolicy::UserRequiredError)
      end

      it "denies random user" do
        policy = described_class.new(other_user, agent_session)
        expect(policy.show?).to be false
      end

      it "allows owner" do
        policy = described_class.new(user, agent_session)
        expect(policy.show?).to be true
      end

      it "allows admin" do
        policy = described_class.new(admin, agent_session)
        expect(policy.show?).to be true
      end
    end
  end

  describe "#edit?" do
    it "raises UserRequiredError for nil user" do
      policy = described_class.new(nil, agent_session)
      expect { policy.edit? }.to raise_error(ApplicationPolicy::UserRequiredError)
    end

    it "denies random user" do
      policy = described_class.new(other_user, agent_session)
      expect(policy.edit?).to be false
    end

    it "allows owner" do
      policy = described_class.new(user, agent_session)
      expect(policy.edit?).to be true
    end
  end

  describe "#update?" do
    it "raises UserRequiredError for nil user" do
      policy = described_class.new(nil, agent_session)
      expect { policy.update? }.to raise_error(ApplicationPolicy::UserRequiredError)
    end

    it "allows owner" do
      policy = described_class.new(user, agent_session)
      expect(policy.update?).to be true
    end
  end

  describe "#destroy?" do
    it "raises UserRequiredError for nil user" do
      policy = described_class.new(nil, agent_session)
      expect { policy.destroy? }.to raise_error(ApplicationPolicy::UserRequiredError)
    end

    it "allows owner" do
      policy = described_class.new(user, agent_session)
      expect(policy.destroy?).to be true
    end

    it "allows admin" do
      policy = described_class.new(admin, agent_session)
      expect(policy.destroy?).to be true
    end
  end
end
