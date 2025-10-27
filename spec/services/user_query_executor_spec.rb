require "rails_helper"

RSpec.describe UserQueryExecutor do
  let(:user) { create(:user) }
  let(:user_query) { create(:user_query, query: "SELECT id FROM users LIMIT 5", created_by: user) }
  let!(:test_users) { create_list(:user, 10) }

  describe "#initialize" do
    it "sets up the executor with valid parameters" do
      executor = UserQueryExecutor.new(user_query)
      expect(executor.user_query).to eq(user_query)
      expect(executor.timeout_ms).to eq(30_000)
      expect(executor.limit).to be_nil
    end

    it "accepts custom timeout and limit" do
      executor = UserQueryExecutor.new(user_query, timeout_ms: 60_000, limit: 100)
      expect(executor.timeout_ms).to eq(60_000)
      expect(executor.limit).to eq(100)
    end
  end

  describe "#valid?" do
    it "returns true for valid executor" do
      executor = UserQueryExecutor.new(user_query)
      expect(executor.valid?).to be true
    end

    it "returns false for inactive user query" do
      user_query.update!(active: false)
      executor = UserQueryExecutor.new(user_query)
      expect(executor.valid?).to be false
      expect(executor.error_messages).to include("User query is not active")
    end

    it "returns false for invalid timeout" do
      executor = UserQueryExecutor.new(user_query, timeout_ms: 0)
      expect(executor.valid?).to be false
      expect(executor.error_messages).to include("Timeout must be between 1 and 300000 milliseconds")
    end

    it "returns false for invalid limit" do
      executor = UserQueryExecutor.new(user_query, limit: 0)
      expect(executor.valid?).to be false
      expect(executor.error_messages).to include("Limit must be between 1 and 100000")
    end
  end

  describe "#execute" do
    it "executes the query and returns users" do
      executor = UserQueryExecutor.new(user_query)
      result = executor.execute

      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.count).to eq(5)
      expect(result.first).to be_a(User)
    end

    it "respects the limit parameter" do
      executor = UserQueryExecutor.new(user_query, limit: 3)
      result = executor.execute

      expect(result.count).to eq(3)
    end

    it "returns empty result for invalid query" do
      invalid_query = create(:user_query, query: "SELECT id FROM users", created_by: user)
      invalid_query.update_column(:query, "SELECT id FROM nonexistent_table")
      executor = UserQueryExecutor.new(invalid_query)

      result = executor.execute
      expect(result).to be_empty
      expect(executor.error_messages).not_to be_empty
    end

    it "returns empty result for inactive query" do
      user_query.update!(active: false)
      executor = UserQueryExecutor.new(user_query)

      result = executor.execute
      expect(result).to be_empty
    end

    it "handles query validation failures" do
      invalid_query = create(:user_query, query: "SELECT id FROM users", created_by: user)
      invalid_query.update_column(:query, "UPDATE users SET name = 'test'")
      executor = UserQueryExecutor.new(invalid_query)

      result = executor.execute
      expect(result).to be_empty
      expect(executor.error_messages).not_to be_empty
    end
  end

  describe "#test_execute" do
    it "executes with limited number of users" do
      executor = UserQueryExecutor.new(user_query)
      result = executor.test_execute(limit: 3)

      expect(result.count).to eq(3)
    end

    it "uses default limit when none specified" do
      executor = UserQueryExecutor.new(user_query)
      result = executor.test_execute

      expect(result.count).to be <= 100 # MAX_TEST_USER_LIMIT
    end
  end

  describe "#estimated_count" do
    it "returns estimated user count" do
      executor = UserQueryExecutor.new(user_query)
      count = executor.estimated_count

      expect(count).to be >= 0
    end

    it "returns 0 for invalid executor" do
      user_query.update!(active: false)
      executor = UserQueryExecutor.new(user_query)

      expect(executor.estimated_count).to eq(0)
    end

    it "handles query execution errors gracefully", :skip => "Database transaction issues in test environment" do
      invalid_query = create(:user_query, query: "SELECT id FROM users", created_by: user)
      invalid_query.update_column(:query, "SELECT id FROM nonexistent_table")
      executor = UserQueryExecutor.new(invalid_query)

      expect(executor.estimated_count).to eq(0)
    end
  end

  describe "error handling" do
    it "handles timeout errors" do
      user_query.update!(max_execution_time_ms: 1)
      allow_any_instance_of(UserQueryExecutor).to receive(:execute_with_timeout).and_raise(PG::QueryCanceled.new("timeout"))

      executor = UserQueryExecutor.new(user_query)
      result = executor.execute

      expect(result).to be_empty
      expect(executor.error_messages).to include(match(/Query execution exceeded maximum time limit/))
    end

    it "handles syntax errors" do
      invalid_query = create(:user_query, query: "SELECT id FRM users", created_by: user)
      allow_any_instance_of(UserQueryExecutor).to receive(:execute_with_timeout).and_raise(PG::SyntaxError.new("syntax error"))

      executor = UserQueryExecutor.new(invalid_query)
      result = executor.execute

      expect(result).to be_empty
      expect(executor.error_messages).to include(match(/Query syntax error/))
    end

    it "handles general execution errors" do
      allow_any_instance_of(UserQueryExecutor).to receive(:execute_with_timeout).and_raise(StandardError.new("general error"))

      executor = UserQueryExecutor.new(user_query)
      result = executor.execute

      expect(result).to be_empty
      expect(executor.error_messages).to include(match(/Query execution failed/))
    end
  end

  describe "execution environment setup" do
    it "sets statement timeout" do
      executor = UserQueryExecutor.new(user_query, timeout_ms: 45_000)

      expect(ActiveRecord::Base.connection).to receive(:execute).with("SET statement_timeout = 45000")
      expect(ActiveRecord::Base.connection).to receive(:execute).with("SET lock_timeout = 45000")
      expect(ActiveRecord::Base.connection).to receive(:execute).with("SET idle_in_transaction_session_timeout = 90000")
      expect(ActiveRecord::Base.connection).to receive(:execute).with("SET row_security = on")

      allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double("result", each: []))
      executor.execute
    end
  end

  describe "query building" do
    it "builds safe query with limit" do
      executor = UserQueryExecutor.new(user_query, limit: 10)
      safe_query = executor.send(:build_safe_query)

      expect(safe_query).to include("LIMIT 10")
      expect(safe_query).to end_with(";")
    end

    it "respects maximum user limit" do
      executor = UserQueryExecutor.new(user_query, limit: 200_000) # Over MAX_USER_LIMIT
      safe_query = executor.send(:build_safe_query)

      expect(safe_query).to include("LIMIT 100000")
    end

    it "replaces existing LIMIT with executor limit" do
      query_with_limit = create(:user_query, query: "SELECT id FROM users LIMIT 20", created_by: user)
      executor = UserQueryExecutor.new(query_with_limit, limit: 10)
      safe_query = executor.send(:build_safe_query)

      expect(safe_query).to include("LIMIT 10")
      expect(safe_query).not_to include("LIMIT 20")
    end
  end

  describe "user ID extraction" do
    it "extracts user IDs from query results" do
      executor = UserQueryExecutor.new(user_query)
      mock_result = double("result", is_a?: true)
      allow(mock_result).to receive(:is_a?).with(PG::Result).and_return(true)
      allow(mock_result).to receive(:each).and_yield({ "id" => "1" }).and_yield({ "id" => "2" })

      user_ids = executor.send(:extract_user_ids, mock_result)
      expect(user_ids).to eq([1, 2])
    end

    it "handles different ID column names" do
      executor = UserQueryExecutor.new(user_query)
      mock_result = double("result", is_a?: true)
      allow(mock_result).to receive(:is_a?).with(PG::Result).and_return(true)
      allow(mock_result).to receive(:each).and_yield({ "user_id" => "3" }).and_yield({ "users.id" => "4" })

      user_ids = executor.send(:extract_user_ids, mock_result)
      expect(user_ids).to eq([3, 4])
    end

    it "filters out nil IDs" do
      executor = UserQueryExecutor.new(user_query)
      mock_result = double("result", is_a?: true)
      allow(mock_result).to receive(:is_a?).with(PG::Result).and_return(true)
      allow(mock_result).to receive(:each).and_yield({ "id" => "1" }).and_yield({ "id" => nil }).and_yield({ "id" => "2" })

      user_ids = executor.send(:extract_user_ids, mock_result)
      expect(user_ids).to eq([1, 2])
    end
  end
end
