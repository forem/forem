# This is an improved version showing how semantic interest extraction SHOULD work
# This file is for reference/discussion - not meant to be used directly

module Ai
  class InterestExtractorImproved
    DIMENSIONS = InterestExtractor::DIMENSIONS

    # Reference texts that represent each dimension
    # These should be rich, representative examples of content in each category
    REFERENCE_TEXTS = {
      "frontend_engineering" => <<~TEXT,
        User interface development, React components, Vue.js, Angular, CSS styling, 
        JavaScript frameworks, web APIs, DOM manipulation, state management, 
        responsive design, frontend architecture, UI/UX implementation
      TEXT
      "backend_engineering" => <<~TEXT,
        API development, server-side logic, database design, REST APIs, GraphQL, 
        microservices, server architecture, authentication, authorization, 
        data processing, backend optimization, server performance
      TEXT
      "mobile_development" => <<~TEXT,
        iOS development, Android apps, React Native, Flutter, mobile UI, 
        native mobile development, mobile performance, app architecture, 
        mobile testing, cross-platform development
      TEXT
      # ... etc for all dimensions
    }.freeze

    def initialize(embedding, ai_client: nil)
      @embedding = embedding
      @ai_client = ai_client || Ai::Base.new
      @reference_embeddings = load_or_compute_reference_embeddings
    end

    # Method 1: Use cosine similarity to reference embeddings
    # This is the most straightforward approach
    def extract_via_similarity
      scores = {}
      
      DIMENSIONS.each do |dim|
        ref_embedding = @reference_embeddings[dim]
        next unless ref_embedding
        
        # Cosine similarity between article embedding and reference embedding
        similarity = cosine_similarity(@embedding, ref_embedding)
        scores[dim] = normalize_score(similarity)
      end
      
      scores
    end

    # Method 2: Use Gemini's generative model for zero-shot classification
    # This leverages the model's understanding of the dimensions
    def extract_via_classification(article_text)
      prompt = build_classification_prompt(article_text)
      response = @ai_client.call(prompt)
      parse_classification_response(response)
    end

    # Method 3: Hybrid approach - use similarity for speed, classification for accuracy
    def extract_hybrid(article_text, threshold: 0.3)
      # Fast path: similarity-based
      similarity_scores = extract_via_similarity
      
      # Only use expensive classification for high-confidence dimensions
      high_confidence = similarity_scores.select { |_, score| score > threshold }
      
      if high_confidence.any?
        # Re-verify with classification
        classification_scores = extract_via_classification(article_text)
        # Merge results, preferring classification for high-confidence items
        similarity_scores.merge(classification_scores) { |_, sim, cls| [sim, cls].max }
      else
        similarity_scores
      end
    end

    private

    def load_or_compute_reference_embeddings
      # Cache reference embeddings in Redis or database
      # They only need to be computed once per dimension
      Rails.cache.fetch("semantic_interest_reference_embeddings", expires_in: 1.day) do
        embeddings = {}
        REFERENCE_TEXTS.each do |dim, text|
          embeddings[dim] = @ai_client.embed(text)
        end
        embeddings
      end
    end

    def cosine_similarity(vec1, vec2)
      return 0.0 if vec1.nil? || vec2.nil? || vec1.size != vec2.size
      
      dot_product = vec1.zip(vec2).sum { |a, b| a * b }
      magnitude1 = Math.sqrt(vec1.sum { |x| x * x })
      magnitude2 = Math.sqrt(vec2.sum { |x| x * x })
      
      return 0.0 if magnitude1.zero? || magnitude2.zero?
      
      dot_product / (magnitude1 * magnitude2)
    end

    def normalize_score(similarity)
      # Cosine similarity ranges from -1 to 1, but embeddings are usually 0-1
      # Normalize to 0-1 range and round
      [[similarity, 0].max, 1].min.round(4)
    end

    def build_classification_prompt(article_text)
      dimensions_list = DIMENSIONS.map.with_index do |dim, idx|
        "#{idx + 1}. #{dim}"
      end.join("\n")

      <<~PROMPT
        Analyze the following article and assign relevance scores (0.0 to 1.0) for each of these semantic dimensions.
        
        Article:
        #{article_text.first(2000)}
        
        Dimensions:
        #{dimensions_list}
        
        For each dimension, provide a score from 0.0 (not relevant) to 1.0 (highly relevant).
        Return ONLY a JSON object with dimension names as keys and scores as values.
        
        Example format:
        {
          "frontend_engineering": 0.8,
          "backend_engineering": 0.2,
          "mobile_development": 0.0,
          ...
        }
      PROMPT
    end

    def parse_classification_response(response)
      # Parse JSON response from Gemini
      JSON.parse(response)
    rescue JSON::ParserError
      # Fallback: try to extract scores from text
      parse_scores_from_text(response)
    end

    def parse_scores_from_text(text)
      scores = {}
      DIMENSIONS.each do |dim|
        # Try to find score in text (e.g., "frontend_engineering: 0.8")
        if match = text.match(/#{dim}['":\s]+([\d.]+)/i)
          scores[dim] = match[1].to_f.clamp(0.0, 1.0).round(4)
        else
          scores[dim] = 0.0
        end
      end
      scores
    end
  end
end

