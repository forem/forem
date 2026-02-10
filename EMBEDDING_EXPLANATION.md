# How Semantic Interests Embeddings Work

## Current Flow

1. **Text → Embedding**: Article text (title, description, tags, body) → Gemini `text-embedding-004` → 768-dimensional vector
2. **Embedding → Dimensions**: Current implementation just samples the vector at intervals (WRONG)
3. **Dimensions → Scores**: Each of 35 dimensions gets a score

## The Problem

The embedding model **does NOT know** about your specific dimensions like "frontend_engineering" or "backend_engineering". 

The embedding is a **dense vector** where:
- Semantically similar texts have similar vectors
- The model learned general semantic relationships from training data
- But it doesn't have a direct mapping to your 35 custom dimensions

## How It Currently Works (Incorrectly)

```ruby
# This is WRONG - just sampling at intervals
value = @embedding[index * (768 / DIMENSIONS.size)] || 0
```

This treats the embedding like it's structured data, but it's not. Each dimension in the embedding doesn't correspond to a specific concept.

## How It SHOULD Work

There are several approaches:

### Option 1: Zero-Shot Classification (Recommended)
Use Gemini's generative model to classify articles into your dimensions:

```ruby
def extract_via_classification(article)
  prompt = build_classification_prompt(article)
  response = ai_client.call(prompt)
  parse_classification_response(response)
end
```

### Option 2: Reference Text Similarity
Create reference texts for each dimension, embed them, and compare:

```ruby
# Pre-compute reference embeddings for each dimension
REFERENCE_TEXTS = {
  "frontend_engineering" => "UI development, React, Vue, CSS, JavaScript, web interfaces...",
  "backend_engineering" => "API development, server logic, databases, REST, GraphQL...",
  # etc.
}

def extract_via_similarity(embedding)
  scores = {}
  REFERENCE_TEXTS.each do |dim, text|
    ref_embedding = embed(text)
    scores[dim] = cosine_similarity(embedding, ref_embedding)
  end
  scores
end
```

### Option 3: Trained Projection Layer
Train a small neural network to map embeddings → dimensions:

```ruby
# Requires training data: articles labeled with dimension scores
# Then train a simple MLP: 768 → 35
def extract_via_projection(embedding)
  projection_model.predict(embedding)
end
```

### Option 4: Use Embedding's Built-in Understanding
Some embedding models can be prompted directly, but text-embedding-004 is embedding-only.

## What Additional Information Could Help?

1. **Article metadata**: Categories, tags (already included), author expertise
2. **User engagement**: Which dimensions correlate with user clicks/reads
3. **Feedback loop**: User corrections to improve classification
4. **Domain-specific training**: Fine-tune on your content
5. **Hierarchical dimensions**: Some dimensions are subsets of others

