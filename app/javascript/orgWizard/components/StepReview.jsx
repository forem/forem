import { h } from 'preact';

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

      {editedData.og_image && (
        <div className="mb-4">
          <label className="crayons-field__label">Cover Image</label>
          <img
            src={editedData.og_image}
            alt="Detected cover image"
            className="radius-default"
            style={{ maxHeight: '160px', width: '100%', objectFit: 'cover', border: '1px solid var(--base-20)' }}
          />
          <p className="fs-xs color-base-50 mt-1">This will be used as your org&apos;s cover image.</p>
        </div>
      )}

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
