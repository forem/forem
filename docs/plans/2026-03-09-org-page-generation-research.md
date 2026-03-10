# Org Page Generation: Research & Improvement Plan

> Research conducted 2026-03-09 across AI page generation pipelines, landing page copywriting,
> prompt engineering for Gemini, and competitor analysis (v0, Relume, Framer, Lovable, Bolt, Durable, Wix, Notion).

---

## The Big Picture

Our current approach is **naive single-shot generation** — one giant prompt, one AI call, hope for the best. Every best-in-class tool (v0, Relume, Framer, Lovable) uses **multi-stage pipelines with constrained output**. Here's what we should steal.

---

## 1. Architecture: Move to a Multi-Stage Pipeline

**Current:** Crawl → Generate (one shot) → Deterministic QA
**Recommended:** Crawl → **Plan** → **Generate per-section** → Assemble → QA → Render

The research is unambiguous: **section-by-section generation nearly doubles keep rates** vs full-page generation (Relume's data). The strongest pattern (used by Relume, Framer Wireframer, and v0):

### Stage 1: Plan (fast/cheap model)
Generate a JSON section outline based on available data:
```json
{
  "sections": [
    {"type": "hero", "headline_angle": "transformation promise", "cta": "Get Started"},
    {"type": "features", "count": 4, "source": "crawled_features"},
    {"type": "social_proof", "format": "quote", "source": "crawled_testimonial"},
    {"type": "community", "posts": ["path/to/post1"], "format": "link_embeds"},
    {"type": "cta", "link": "https://...", "button": "Try the API"}
  ]
}
```
The AI selects which sections to include based on what content actually exists. Empty sections become impossible.

### Stage 2: Generate (capable model)
Fill each section using the corresponding liquid tag template. Each section gets a focused prompt with only its relevant context — no "lost in the middle" problem.

### Stage 3: Assemble + QA (deterministic)
Combine sections, run the existing deterministic QA pipeline (broken icons, empty tags, missing posts), validate rendering.

**Why this is better:**
- Failures are localized (bad feature section? regenerate just that one)
- Each section gets focused attention instead of competing for context
- The plan step prevents empty/irrelevant sections
- Cheaper overall (planning is cheap, only content generation needs the big model)

---

## 2. Prompt Engineering: What the Research Says

### "Lost in the Middle" Effect
LLMs attend most to the **beginning** and **end** of the prompt, with significant degradation in the middle. Our current prompt puts critical rules at the end (good) but buries the tag reference in the middle.

**Fix:** Restructure to:
1. **Beginning** (highest attention): Role + critical constraints ("NEVER invent tags")
2. **Middle** (lowest attention): Bulky reference material (tag guide, crawled data)
3. **End** (high attention): Output format + repeat critical constraints

### Add One Gold-Standard Example
Research paper "Two Shots Are Enough" found 1-2 examples is the sweet spot. Gemini specifically benefits from examples more than verbose instructions. We should include **one complete example page** showing correct liquid tag usage, section flow, and tone.

### Gemini-Specific Tips
- Keep temperature at **1.0** for Gemini 3 (it's optimized for this)
- Don't add explicit chain-of-thought for thinking-enabled models
- Prefer **shorter, more direct** prompts over verbose ones
- Use the **PTCF framework**: Persona, Task, Context, Format

### XML-Structured Prompts
XML tags create "semantic anchoring" that helps models maintain context:
```xml
<available_tags>...</available_tags>
<crawled_data>...</crawled_data>
<instructions>...</instructions>
<example_output>...</example_output>
```

---

## 3. Consider JSON Structured Output → Server-Side Rendering

The nuclear option for eliminating "AI invented a non-existent tag" errors: **don't let the AI write liquid tags at all**.

Instead, have Gemini return structured JSON:
```json
{
  "hero": {"headline": "Build Communications at Scale", "description": "..."},
  "features": [
    {"icon": "code", "title": "REST APIs", "description": "..."},
    {"icon": "book", "title": "Documentation", "description": "..."}
  ],
  "quotes": [{"author": "Jane", "role": "CTO", "text": "..."}],
  "cta": {"link": "https://...", "button": "Get Started", "description": "..."}
}
```

Then render liquid tags **server-side from templates**. The AI never sees liquid syntax, so it can't break it. This is the approach Notion uses (AI fills structured slots, system renders the format).

**Trade-off:** Less creative freedom in layout, but dramatically more reliable output.

---

## 4. Landing Page Copywriting: What Actually Works

### Evil Martians Study (100 dev tool landing pages, 2025)
Two golden rules: **no salesy BS** and **clever and simple wins**.

Key findings:
- Developers are allergic to marketing fluff. Language should inform and educate, not sell.
- "Show don't tell" — demonstrate capabilities through code snippets and visuals, not specification lists.
- The best dev pages (Stripe, Twilio, Vercel, Supabase) organize content around real developer goals, not product categories.
- Vercel's homepage distills everything to three words: "Develop. Preview. Ship."
- Supabase: "Build in a weekend. Scale to millions." — a transformation promise.
- Clean design with solid typography, clear layout, and breathing room. Most avoid flashy interactions.

### Copywriting Frameworks by Page Type

**AIDA (Attention, Interest, Desire, Action)** — Maps directly to section ordering: Hero grabs Attention, Features build Interest, Social Proof creates Desire, CTA drives Action. Best for marketing pages.

**PAS (Problem, Agitation, Solution)** — Start with the audience's pain point, agitate by highlighting consequences, present the product as the solution. Best for developer pages targeting frustrated developers.

**StoryBrand** — Positions the customer as the hero and the brand as the guide. The org is not the star of the page; the visitor's journey is. Best for community pages.

**Key insight:** Elite marketers hybridize frameworks rather than using one rigidly. The prompt should select framework emphasis based on `page_type`.

### Section Order (AIDA mapping)
1. **Hero** — headline + subhead + CTA (the 5-second pitch)
2. **Social proof / logos** — immediate credibility
3. **Features** — 3-6 highlights, benefit-led not feature-led
4. **Deeper social proof** — testimonials, community content
5. **Getting started / docs** — reduce friction
6. **Team** (if relevant)
7. **Final CTA** — restate value, close the loop

7-8 core sections is the sweet spot. An empty section is worse than no section.

### Per-Page-Type Tone Guidance

| Page Type | Framework | Tone | Avoid |
|-----------|-----------|------|-------|
| Developer | PAS (Problem-Agitation-Solution) | Technical, concise, show-don't-tell | Marketing fluff, "revolutionary", "game-changing" |
| Marketing | AIDA (Attention-Interest-Desire-Action) | Polished, benefit-focused, transformation narrative | Jargon, feature dumps |
| Community | StoryBrand (visitor as hero) | Warm, inclusive, "we" language | Corporate speak, self-congratulation |
| Talent | Authentic voice | People-first, specific culture details | Platitudes, stock-photo energy |

### Hero Section Formula
- Headline: Benefit-driven or problem-solving, clarity over cleverness. 8 of 10 people read the headline but only 2 read further.
- Subheadline: Specific explanation of what you offer, for whom, and why.
- CTA: Action-oriented, benefit-focused language ("Get Started" not "Submit").

### CTA Best Practices
- **One primary action** per page, repeated 2-3 times (hero, mid-page, bottom)
- Pages with a single CTA convert at 13.5% vs 10.5% for multiple different CTAs
- Action verbs: "Get Started", "View Docs", "Try the API" (not "Submit" or "Learn More")
- Developer-specific: "View Docs", "See It in Action", "Get the SDK"

### Word Count
- 300-600 words total for a focused page
- Headlines under 10 words
- Feature descriptions under 30 words
- Users read ~28% of words on a webpage — content must be skimmable

### Social Proof (in order of effectiveness for dev platforms)
1. Usage metrics — GitHub stars, download counts, active users
2. Company/client logos — recognizable names build instant credibility
3. Community content — user-generated posts, real engagement
4. Individual testimonials — with name, role, and photo
5. Expert endorsements — known figures in the developer community

---

## 5. What Makes Competitor Tools Feel "Magical"

### v0.dev (Vercel)
- **Composite architecture**: RAG + frontier LLM + AutoFix (a dedicated model that catches errors mid-stream in <250ms)
- Constrained to React + Tailwind + shadcn/ui — opinionated stack the model knows deeply
- Streaming preview (watch UI materializing as tokens generate)
- Visual selection mode (click on a component to specify what to change)

### Relume
- **Two-phase pipeline**: Sitemap (structure) → Wireframe (content). Most relevant to our approach.
- Each section is a separately promptable unit
- 1000+ pre-built section components
- Section-by-section generation nearly doubled keep rates vs full-page

### Framer AI
- Separates **Wireframer** (generates layout/structure) from **Workshop** (generates interactive components)
- Automatic responsive breakpoints
- Components auto-inherit canvas styles for visual consistency

### Lovable
- **LLM-as-file-selector**: uses an LLM to select only relevant files instead of feeding all context
- Browser-side AST processing: bidirectional mapping between visual DOM and JSX source
- "Visual Edits": click any element → trace to exact code responsible
- Constrained stack (React + Tailwind + Supabase) dramatically reduces surprise outcomes

### Bolt.new
- Full Node.js environment in the browser (WebContainers) — AI controls entire runtime
- Zero setup: type → it runs → in your browser
- Speed is the differentiator: prompt → fully coded app in <30 seconds

### Durable.co
- **Three inputs only**: business type, name, location → complete website in 30 seconds
- Industry-specific content generation (plumber's site reads differently from personal trainer's)
- "More than you asked for" pattern: includes CRM + invoicing automatically

### Wix AI
- **Conversational questionnaire** intake — AI chatbot asks questions, builds a site profile
- Auto-installs relevant apps (booking for salons, e-commerce for shops) based on business type
- 15+ AI tools post-generation for refinement

### Notion AI
- **Template + AI Blocks pattern**: AI fills structured slots within proven layouts
- "Constrain the structure, generate the content" approach
- Custom Autofill Properties: database properties that auto-populate via custom AI prompts

### Cross-Cutting Lessons
1. **Constrained, opinionated stacks win.** Open-ended generation produces generic results; constrained generation produces professional results. Our liquid tag library IS our constrained stack.
2. **Streaming + live preview creates the "wow."** Watching something build itself has enormous psychological impact.
3. **The post-processor / error-fix layer is underrated.** v0's AutoFix, our deterministic QA — generation + automated quality checking is fundamentally better than generation alone.
4. **Multi-step intake produces better results than single prompts.** Structure → content → styling mirrors how human designers work.
5. **Industry/context awareness elevates generic to professional.** Knowing the domain transforms "AI-generated" to "professionally designed."
6. **The "more than you asked for" pattern creates delight.** Auto-set brand colors, auto-fill social links, suggest related tags.

---

## 6. Concrete Implementation Priorities

Ranked by impact-to-effort ratio:

### Quick Wins (can do now)
1. **Add a gold-standard example** to the prompt — one complete page showing perfect liquid tag usage
2. **Restructure prompt** for "lost in the middle" — rules at beginning AND end, reference material in middle
3. **Expand page_type_guidance** with specific copywriting frameworks, word-choice rules, and anti-patterns per type
4. **Add word count targets** to the prompt (300-600 words, headlines <10 words)
5. **Better CTA guidance** — tell AI to place offers at hero, mid-page, and bottom positions

### Medium Effort (next iteration)
6. **Planning step** — add a fast model call to generate a section outline before the main generation
7. **Section-level generation** — generate each section independently with focused prompts
8. **Structured JSON output** — have AI return JSON, render liquid tags server-side (eliminates tag invention entirely)
9. **Streaming preview** — show sections appearing one by one as they generate

### Bigger Bets (future)
10. **Multiple layout templates** — curate 3-5 "gold standard" page templates that the AI selects from and fills
11. **Visual section-level editing** — click a section in the preview to regenerate just that section
12. **A/B test different generations** — generate 2-3 variants, let the user pick

---

## Sources

### AI Page Generation Pipelines
- [The Ultimate Guide to Prompt Engineering in 2026 - Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)
- [Context Engineering Guide - Prompting Guide](https://www.promptingguide.ai/guides/context-engineering-guide)
- [Self-Refine: Iterative Refinement with Self-Feedback](https://arxiv.org/abs/2303.17651)
- [LLM-as-a-Judge Guide 2026 - Label Your Data](https://labelyourdata.com/articles/llm-as-a-judge)
- [Lost in the Middle: How Language Models Use Long Contexts](https://arxiv.org/abs/2307.03172)
- [Gemini API Structured Outputs](https://ai.google.dev/gemini-api/docs/structured-output)
- [Context Caching - Gemini API](https://ai.google.dev/gemini-api/docs/caching)
- [Relume AI - Building a Sitemap with AI](https://www.relume.io/resources/docs/building-a-sitemap-with-ai)

### Landing Page Copywriting
- [We studied 100 dev tool landing pages - Evil Martians](https://evilmartians.com/chronicles/we-studied-100-devtool-landing-pages-here-is-what-actually-works-in-2025)
- [How Stripe, Twilio, and GitHub Built Dev Trust](https://business.daily.dev/resources/cracking-the-code-how-stripe-twilio-and-github-built-dev-trust/)
- [Writing Copy for Landing Pages - Stripe Atlas](https://stripe.com/guides/atlas/landing-page-copy)
- [How 30 Dev Tool Homepages Put Developers First](https://everydeveloper.com/developer-tool-homepages/)
- [2025 Copywriting Frameworks Outperforming AIDA](https://medium.com/@drishtisethi8/2025-copywriting-frameworks-that-are-outperforming-aida-and-how-to-use-them-bf161f6c45a4)
- [Landing Page Copywriting Frameworks: PAS, AIDA, BAB](https://www.landy-ai.com/blog/landing-page-copywriting-frameworks)
- [15 Call to Action Examples - Unbounce](https://unbounce.com/conversion-rate-optimization/call-to-action-examples/)
- [Social Proof Examples for Landing Pages - MailerLite](https://www.mailerlite.com/blog/social-proof-examples-for-landing-pages)

### Prompt Engineering for Gemini
- [Prompt design strategies - Gemini API](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Gemini 3 Prompting Guide - Google Cloud](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/gemini-3-prompting-guide)
- [Two Shots Are Enough: Reliable Constrained Generation](https://exascale.info/assets/pdf/mondal2025bigdata.pdf)
- [Few Shot Prompting Guide - PromptHub](https://www.prompthub.us/blog/the-few-shot-prompting-guide)
- [XML Tags for Structured Prompts - Claude Docs](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags)
- [RouteLLM Framework - LMSYS](https://lmsys.org/blog/2024-07-01-routellm/)
- [Gemini Thinking Documentation](https://ai.google.dev/gemini-api/docs/thinking)

### Competitor Analysis
- [Introducing the v0 composite model family](https://vercel.com/blog/v0-composite-model-family)
- [How we made v0 an effective coding agent](https://vercel.com/blog/how-we-made-v0-an-effective-coding-agent)
- [How we built the Visual Edits feature - Lovable](https://lovable.dev/blog/visual-edits)
- [The Lovable Prompting Bible](https://lovable.dev/blog/2025-01-16-lovable-prompting-handbook)
- [Framer Wireframer](https://www.framer.com/wireframer/)
- [Bolt.new GitHub Repository](https://github.com/stackblitz/bolt.new)
- [Durable AI Website Builder](https://durable.com/ai-website-builder)
- [Wix AI Website Builder](https://www.wix.com/ai-website-builder)
- [Notion AI for databases](https://www.notion.com/help/autofill)
