require "rails_helper"

RSpec.describe UserQueryValidator do
  describe "#valid?" do
    context "with valid queries" do
      it "validates a simple user query" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE created_at > '2023-01-01'")
        expect(validator.valid?).to be true
        expect(validator.error_messages).to be_empty
      end

      it "validates a query with joins" do
        validator = UserQueryValidator.new("SELECT users.id FROM users JOIN profiles ON users.id = profiles.user_id WHERE profiles.bio IS NOT NULL")
        expect(validator.valid?).to be true
      end

      it "validates a query with complex WHERE clause" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE created_at > '2023-01-01' AND email IS NOT NULL AND registered = true")
        expect(validator.valid?).to be true
      end

      it "validates a query with ORDER BY and LIMIT" do
        validator = UserQueryValidator.new("SELECT id FROM users ORDER BY created_at DESC LIMIT 100")
        expect(validator.valid?).to be true
      end

      it "validates a query with GROUP BY and HAVING" do
        validator = UserQueryValidator.new("SELECT users.id FROM users JOIN articles ON users.id = articles.user_id GROUP BY users.id HAVING COUNT(articles.id) > 5")
        expect(validator.valid?).to be true
      end
    end

    context "with invalid queries" do
      it "rejects blank queries" do
        validator = UserQueryValidator.new("")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query cannot be blank")
      end

      it "rejects queries that don't start with SELECT" do
        validator = UserQueryValidator.new("UPDATE users SET name = 'test'")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query must start with SELECT")
      end

      it "rejects queries that don't target users table" do
        validator = UserQueryValidator.new("SELECT id FROM articles")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query must target the users table")
      end

      it "rejects queries that don't select user ID" do
        validator = UserQueryValidator.new("SELECT name FROM users")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query must select user ID (id or users.id)")
      end

      it "rejects queries with forbidden keywords" do
        validator = UserQueryValidator.new("SELECT id FROM users; DELETE FROM users;")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains forbidden keyword: DELETE")
      end

      it "rejects queries with suspicious patterns" do
        validator = UserQueryValidator.new("SELECT id FROM users -- comment")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains suspicious pattern: /--/")
      end

      it "rejects queries with unauthorized tables" do
        validator = UserQueryValidator.new("SELECT id FROM users JOIN secret_table ON users.id = secret_table.user_id")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query references unauthorized tables: secret_table")
      end

      it "rejects queries that exceed maximum length" do
        long_query = "SELECT id FROM users WHERE " + "created_at > '2023-01-01' AND " * 1000
        validator = UserQueryValidator.new(long_query)
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query exceeds maximum length of 10000 characters")
      end

      it "rejects queries with unbalanced parentheses" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE (created_at > '2023-01-01'")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains unbalanced parentheses")
      end

      it "rejects modifying queries" do
        validator = UserQueryValidator.new("SELECT id FROM users; INSERT INTO logs VALUES ('test');")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains forbidden keyword: INSERT")
      end
    end

    context "with dangerous patterns" do
      it "rejects queries with SQL comments" do
        validator = UserQueryValidator.new("SELECT id FROM users /* dangerous comment */")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains suspicious pattern: /\\/\\*.*\\*\\//")
      end

      it "rejects queries with system functions" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE user() = 'admin'")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains suspicious pattern: /\\buser\\s*\\(/i")
      end

      it "rejects queries with sleep functions" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE pg_sleep(1)")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains suspicious pattern: /pg_sleep\\s*\\(/i")
      end

      it "rejects queries with information schema access" do
        validator = UserQueryValidator.new("SELECT id FROM users WHERE id IN (SELECT table_name FROM information_schema.tables)")
        expect(validator.valid?).to be false
        expect(validator.error_messages).to include("Query contains suspicious pattern: /information_schema/i")
      end
    end
  end

  describe "#error_messages" do
    it "returns empty array for valid queries" do
      validator = UserQueryValidator.new("SELECT id FROM users")
      validator.valid?
      expect(validator.error_messages).to be_empty
    end

    it "returns error messages for invalid queries" do
      validator = UserQueryValidator.new("UPDATE users SET name = 'test'")
      validator.valid?
      expect(validator.error_messages).not_to be_empty
      expect(validator.error_messages).to include("Query must start with SELECT")
    end
  end

  describe "table name extraction" do
    it "extracts table names from FROM clause" do
      validator = UserQueryValidator.new("SELECT id FROM users WHERE created_at > '2023-01-01'")
      expect(validator.send(:extract_table_names, "SELECT id FROM users")).to include("users")
    end

    it "extracts table names from JOIN clauses" do
      validator = UserQueryValidator.new("SELECT users.id FROM users JOIN profiles ON users.id = profiles.user_id")
      expect(validator.send(:extract_table_names, "SELECT users.id FROM users JOIN profiles ON users.id = profiles.user_id")).to include("users", "profiles")
    end

    it "extracts table names from LEFT JOIN clauses" do
      validator = UserQueryValidator.new("SELECT users.id FROM users LEFT JOIN articles ON users.id = articles.user_id")
      expect(validator.send(:extract_table_names, "SELECT users.id FROM users LEFT JOIN articles ON users.id = articles.user_id")).to include("users", "articles")
    end
  end

  describe "parentheses balancing" do
    it "validates balanced parentheses" do
      validator = UserQueryValidator.new("SELECT id FROM users WHERE (created_at > '2023-01-01')")
      expect(validator.send(:balanced_parentheses?)).to be true
    end

    it "detects unbalanced parentheses" do
      validator = UserQueryValidator.new("SELECT id FROM users WHERE (created_at > '2023-01-01'")
      expect(validator.send(:balanced_parentheses?)).to be false
    end

    it "handles nested parentheses" do
      validator = UserQueryValidator.new("SELECT id FROM users WHERE (created_at > '2023-01-01' AND (email IS NOT NULL))")
      expect(validator.send(:balanced_parentheses?)).to be true
    end
  end
end

