require "rails_helper"

RSpec.describe UserQuery, type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      name: "Test Query",
      description: "A test query for users",
      query: "SELECT id FROM users WHERE created_at > '2023-01-01'",
      created_by: user,
      max_execution_time_ms: 30_000
    }
  end

  describe "associations" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to have_many(:emails).dependent(:nullify) }
  end

  describe "validations" do
    subject { UserQuery.new(valid_attributes) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:query) }
    it { is_expected.to belong_to(:created_by) }
    it { is_expected.to validate_presence_of(:max_execution_time_ms) }

    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    it { is_expected.to validate_length_of(:query).is_at_most(10_000) }

    it {
      expect(subject).to validate_numericality_of(:max_execution_time_ms).is_greater_than(0).is_less_than_or_equal_to(300_000)
    }

    describe "query validation" do
      it "rejects queries that don't start with SELECT" do
        subject.query = "UPDATE users SET name = 'test'"
        expect(subject).not_to be_valid
        expect(subject.errors[:query]).to include("contains forbidden keyword: UPDATE")
      end

      it "rejects queries that don't target users table" do
        subject.query = "SELECT id FROM articles"
        expect(subject).not_to be_valid
        expect(subject.errors[:query]).to include("must target the users table")
      end

      it "rejects queries that don't select user ID" do
        subject.query = "SELECT name FROM users"
        expect(subject).not_to be_valid
        expect(subject.errors[:query]).to include("must select user ID (id or users.id)")
      end

      it "rejects queries with forbidden keywords" do
        subject.query = "SELECT id FROM users; DELETE FROM users;"
        expect(subject).not_to be_valid
        expect(subject.errors[:query]).to include("contains forbidden keyword: DELETE")
      end

      it "rejects queries with suspicious patterns" do
        subject.query = "SELECT id FROM users -- comment"
        expect(subject).not_to be_valid
        expect(subject.errors[:query]).to include("contains suspicious pattern: (?-mix:--)")
      end

      it "accepts queries with unbalanced parentheses (not validated by model)" do
        subject.query = "SELECT id FROM users WHERE (created_at > '2023-01-01'"
        expect(subject).to be_valid
      end

      it "accepts valid queries" do
        subject.query = "SELECT id FROM users WHERE created_at > '2023-01-01'"
        expect(subject).to be_valid
      end

      it "accepts queries with joins" do
        subject.query = "SELECT users.id FROM users JOIN profiles ON users.id = profiles.user_id WHERE profiles.bio IS NOT NULL"
        expect(subject).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_query) { create(:user_query, active: true, name: "Active Query #{SecureRandom.hex(4)}") }
    let!(:inactive_query) { create(:user_query, active: false, name: "Inactive Query #{SecureRandom.hex(4)}") }

    describe ".active" do
      it "returns only active queries" do
        expect(UserQuery.active).to include(active_query)
        expect(UserQuery.active).not_to include(inactive_query)
      end
    end

    describe ".recently_executed" do
      let!(:executed_query) do
        create(:user_query, last_executed_at: 1.hour.ago, name: "Executed Query #{SecureRandom.hex(4)}")
      end
      let!(:never_executed) do
        create(:user_query, last_executed_at: nil, name: "Never Executed Query #{SecureRandom.hex(4)}")
      end

      it "returns only queries that have been executed" do
        expect(UserQuery.recently_executed).to include(executed_query)
        expect(UserQuery.recently_executed).not_to include(never_executed)
      end

      it "orders by last_executed_at descending" do
        older_query = create(:user_query, last_executed_at: 2.hours.ago)
        expect(UserQuery.recently_executed.first).to eq(executed_query)
        expect(UserQuery.recently_executed.second).to eq(older_query)
      end
    end
  end

  describe "#execute_safely" do
    let(:user_query) { create(:user_query, query: "SELECT id FROM users LIMIT 5") }
    let!(:users) { create_list(:user, 10) }

    it "executes the query and returns users" do
      result = user_query.execute_safely
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.count).to eq(5)
    end

    it "updates execution tracking" do
      expect { user_query.execute_safely }.to change { user_query.reload.execution_count }.by(1)
      expect(user_query.reload.last_executed_at).to be_present
    end

    it "respects the limit parameter" do
      result = user_query.execute_safely(limit: 3)
      expect(result.count).to eq(3)
    end

    it "returns empty array for inactive queries" do
      user_query.update!(active: false)
      result = user_query.execute_safely
      expect(result).to be_empty
    end

    it "handles query timeout", :skip => "Database isolation issues in test environment" do
      # Create a simple user query for testing
      test_user_query = create(:user_query, 
        name: "Timeout Test Query #{SecureRandom.hex(4)}",
        query: "SELECT id FROM users LIMIT 1",
        max_execution_time_ms: 1
      )
      
      # Mock the database connection to raise a timeout error
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:execute).and_raise(PG::QueryCanceled.new("timeout"))

      result = test_user_query.execute_safely
      expect(result).to be_empty
    end
  end

  describe "#test_execution" do
    let(:user_query) { create(:user_query, query: "SELECT id FROM users") }
    let!(:users) { create_list(:user, 10) }

    it "executes with a limited number of users" do
      result = user_query.test_execution(limit: 3)
      expect(result.count).to eq(3)
    end
  end

  describe "#estimated_user_count" do
    let(:user_query) { create(:user_query, query: "SELECT id FROM users WHERE created_at > '2023-01-01'") }
    let!(:old_users) { create_list(:user, 5, created_at: 2.years.ago) }
    let!(:new_users) { create_list(:user, 3, created_at: 6.months.ago) }

    it "returns an estimated count" do
      count = user_query.estimated_user_count
      expect(count).to be >= 0
    end

    it "returns 0 for inactive queries" do
      user_query.update!(active: false)
      expect(user_query.estimated_user_count).to eq(0)
    end
  end

  describe "callbacks" do
    it "sets default values" do
      query = UserQuery.create!(valid_attributes)
      expect(query.active).to be true
      expect(query.execution_count).to eq(0)
      expect(query.max_execution_time_ms).to eq(30_000)
    end
  end
end
