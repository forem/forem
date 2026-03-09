import { h } from 'preact';

const PAGE_TYPES = [
  { value: 'developer', label: 'Developer-Focused', description: 'Docs, APIs, code samples, and technical resources' },
  { value: 'marketing', label: 'Marketing Showcase', description: 'Product highlights, testimonials, and calls-to-action' },
  { value: 'community', label: 'Community Hub', description: 'Team members, DEV posts, and community engagement' },
  { value: 'talent', label: 'Talent & Careers', description: 'Team culture, open roles, and why developers should join' },
];

export function StepReview({
  crawlData,
  editedData,
  selectedPosts,
  loading,
  onEditData,
  onTogglePost,
  onGenerate,
  onBack,
}) {
  if (loading) {
    return (
      <div className="text-center py-8">
        <div className="crayons-indicator crayons-indicator--loading" />
        <p className="fs-l mt-4 color-base-70">Generating your page...</p>
        <p className="fs-s color-base-60">Our AI is crafting something beautiful using your content and DEV community posts.</p>
      </div>
    );
  }

  const devPosts = crawlData?.dev_posts || [];

  return (
    <div>
      <h2 className="fs-xl mb-4">Here&apos;s what we found</h2>

      <div className="mb-4">
        <label className="crayons-field__label" htmlFor="wizard-tagline">Tagline</label>
        <input
          id="wizard-tagline"
          className="crayons-textfield"
          value={editedData.title || ''}
          onInput={(e) => onEditData({ ...editedData, title: e.target.value })}
        />
      </div>

      <div className="mb-4">
        <label className="crayons-field__label" htmlFor="wizard-description">Description</label>
        <textarea
          id="wizard-description"
          className="crayons-textfield"
          rows={3}
          value={editedData.description || ''}
          onInput={(e) => onEditData({ ...editedData, description: e.target.value })}
        />
      </div>

      {editedData.detected_color && (
        <div className="mb-4">
          <label className="crayons-field__label" htmlFor="wizard-color">Brand Color</label>
          <div className="flex items-center gap-3">
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '6px',
                backgroundColor: editedData.detected_color,
                border: '1px solid var(--base-30)',
              }}
            />
            <input
              id="wizard-color"
              type="color"
              value={editedData.detected_color}
              onChange={(e) => onEditData({ ...editedData, detected_color: e.target.value })}
              style={{ width: '36px', height: '36px', padding: 0, cursor: 'pointer' }}
            />
            <span className="fs-s color-base-60">{editedData.detected_color}</span>
          </div>
        </div>
      )}

      <div className="mb-6">
        <h3 className="fs-l mb-2">What kind of page?</h3>
        <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(2, 1fr)' }}>
          {PAGE_TYPES.map((pt) => (
            <button
              key={pt.value}
              type="button"
              className={`crayons-card p-3 text-left cursor-pointer ${
                editedData.page_type === pt.value ? 'border-accent-brand' : ''
              }`}
              style={{
                border: editedData.page_type === pt.value ? '2px solid var(--accent-brand)' : '1px solid var(--base-20)',
              }}
              onClick={() => onEditData({ ...editedData, page_type: pt.value })}
            >
              <span className="fw-bold fs-s">{pt.label}</span>
              <p className="fs-xs color-base-60 mt-1 mb-0">{pt.description}</p>
            </button>
          ))}
        </div>
      </div>

      {devPosts.length > 0 && (
        <div className="mb-6">
          <h3 className="fs-l mb-2">Popular on DEV</h3>
          <p className="fs-s color-base-60 mb-3">Select posts to feature on your page:</p>
          <ul className="list-none p-0">
            {devPosts.map((post) => (
              <li key={post.id} className="flex items-center gap-2 py-2 border-b border-base-10">
                <input
                  type="checkbox"
                  className="crayons-checkbox"
                  checked={selectedPosts.includes(post.id)}
                  onChange={() => onTogglePost(post.id)}
                  id={`post-${post.id}`}
                />
                <label htmlFor={`post-${post.id}`} className="flex-1 cursor-pointer">
                  <span className="fw-medium">{post.title}</span>
                  <span className="fs-s color-base-60 ml-2">{post.reactions} reactions</span>
                </label>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="flex gap-2 mt-6">
        <button className="crayons-btn" onClick={onGenerate}>Generate My Page</button>
        <button className="crayons-btn crayons-btn--ghost" onClick={onBack}>Back</button>
      </div>
    </div>
  );
}
