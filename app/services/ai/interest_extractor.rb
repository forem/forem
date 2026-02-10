module Ai
  class InterestExtractor
    # A fixed list of semantic dimensions to map embeddings to.
    # This ensures we have a stable and queryable feature set.
    # In a production environment, these could be refined over time.
    DIMENSIONS = [
      # Broad Technical Domains (Abstracted from specific languages/tools)
      "frontend_engineering",    # UI, State management, CSS, Web APIs
      "backend_engineering",     # APIs, Server logic, DB interactions
      "mobile_development",      # iOS, Android, Cross-platform
      "systems_programming",     # Low-level, Embedded, OS, Compilers
      "cloud_infrastructure",    # DevOps, SRE, Serverless, Containers
      "data_engineering",        # Databases, Pipelines, Analytics, SQL/NoSQL concepts
      "artificial_intelligence", # ML, LLMs, Data Science
      "cyber_security",          # AppSec, InfoSec, Cryptography
      "blockchain_web3",         # Decentralized systems
      "hardware_iot",            # Electronics, Edge computing

      # Cross-Cutting Concerns
      "software_architecture",   # System design, Distributed systems, Patterns
      "performance_scale",       # Optimization, High availability, Latency
      "developer_experience",    # Tooling, IDEs, Productivity, CLI
      "quality_assurance",       # Testing, TDD, Reliability
      "accessibility",           # Inclusive design, A11y
      "ui_ux_design",            # Visual design, User experience principles

      # Content "Lenses" & Types
      "beginner_guides",         # Tutorials, 101s, "How to start"
      "advanced_internals",      # Deep dives, Source code analysis, Expert techniques
      "engineering_leadership",  # Management, Agile, Hiring, Team dynamics
      "career_growth",           # Soft skills, Mentorship, Job hunting, Burnout
      "industry_trends",         # News, Hype cycles, "State of X"
      "computer_science",        # Theory, Algorithms, Math, Academic
      "history_philosophy",      # History of tech, Ethics, Impact on society
      "meta_commentary"          # Opinions on the industry, Programming culture
    ].freeze

    def initialize(embedding)
      @embedding = embedding
    end

    # Projects a high-dimensional embedding onto our fixed dimensions.
    # For simplicity in this implementation, we use a simple projection logic.
    # In a real-world scenario, you might use a pre-trained mapping or a PCA-like projection.
    def extract
      # We create a pseudo-hash of interests.
      # Since we don't have a pre-trained projection matrix here, 
      # we'll use a deterministic approach to sample the embedding space.
      interests = {}
      
      DIMENSIONS.each_with_index do |dim, index|
        # Sample the embedding at intervals. Since embeddings are dense and somewhat distributed,
        # this gives us a "signature" of the content.
        # text-embedding-004 has 768 dimensions.
        value = @embedding[index * (768 / DIMENSIONS.size)] || 0
        interests[dim] = value.round(4)
      end
      
      interests
    end

    def self.dot_product(profile1, profile2)
      return 0.0 if profile1.blank? || profile2.blank?
      
      sum = 0.0
      DIMENSIONS.each do |dim|
        sum += (profile1[dim].to_f * profile2[dim].to_f)
      end
      sum
    end
  end
end
