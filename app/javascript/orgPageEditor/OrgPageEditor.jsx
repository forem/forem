import { h } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import { EditorBody } from '../article-form/components/EditorBody';
import { Tabs } from '../article-form/components/Tabs';

const TEXTAREA_ID = 'org_page_markdown';
const PLACEHOLDER = `Use Markdown and Liquid tags to customize your org page.\n\nExample:\n{% org_team your-org-slug %}\n{% org_team your-org-slug role=admins limit=5 %}\n{% org_posts your-org-slug %}\n{% org_posts your-org-slug limit=5 sort=reactions min_reactions=10 since=30d %}`;

const HEADER_HEIGHT = 56;

export const OrgPageEditor = ({ defaultValue, textAreaName, previewUrl }) => {
  const [previewShowing, setPreviewShowing] = useState(false);
  const [previewHTML, setPreviewHTML] = useState('');
  const [previewLoading, setPreviewLoading] = useState(false);
  const [previewError, setPreviewError] = useState(null);
  const bodyRef = useRef(defaultValue);
  const containerRef = useRef(null);
  const headerRef = useRef(null);
  const [fixedStyle, setFixedStyle] = useState(null);

  useEffect(() => {
    const update = () => {
      const container = containerRef.current;
      if (!container) return;

      const rect = container.getBoundingClientRect();
      const headerEl = headerRef.current;
      const headerH = headerEl ? headerEl.offsetHeight : 40;

      if (rect.top < HEADER_HEIGHT && rect.bottom > HEADER_HEIGHT + headerH) {
        setFixedStyle({
          position: 'fixed',
          top: `${HEADER_HEIGHT}px`,
          left: `${rect.left}px`,
          width: `${rect.width}px`,
        });
      } else {
        setFixedStyle(null);
      }
    };

    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update, { passive: true });
    update();
    return () => {
      window.removeEventListener('scroll', update);
      window.removeEventListener('resize', update);
    };
  }, []);

  const handleChange = (e) => {
    bodyRef.current = e.target.value;
  };

  const scrollToEditor = () => {
    const container = containerRef.current;
    if (container) {
      const top = container.getBoundingClientRect().top + window.scrollY - HEADER_HEIGHT - 8;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  };

  const togglePreview = () => {
    if (previewShowing) {
      setPreviewShowing(false);
      scrollToEditor();
      return;
    }

    setPreviewShowing(true);
    setPreviewLoading(true);
    setPreviewError(null);
    scrollToEditor();

    fetch(previewUrl, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': window.csrfToken,
      },
      body: JSON.stringify({ body_markdown: bodyRef.current }),
      credentials: 'same-origin',
    })
      .then((res) => res.json())
      .then((data) => {
        if (data.error) {
          setPreviewError(data.error);
        } else {
          setPreviewHTML(data.processed_html);
        }
        setPreviewLoading(false);
      })
      .catch(() => {
        setPreviewError('Failed to load preview');
        setPreviewLoading(false);
      });
  };

  return (
    <div className="crayons-article-form__content" ref={containerRef}>
      {fixedStyle && (
        <div className="crayons-article-form__header--placeholder" />
      )}
      <div
        className={`crayons-article-form__header${fixedStyle ? ' crayons-article-form__header--fixed' : ''}`}
        ref={headerRef}
        style={fixedStyle || undefined}
      >
        <Tabs previewShowing={previewShowing} onPreview={togglePreview} />
      </div>
      {previewShowing ? (
        <div className="crayons-article-form__body text-padding">
          {previewLoading && (
            <p className="fs-base color-base-60 p-4">Loading preview...</p>
          )}
          {previewError && (
            <div className="crayons-notice crayons-notice--danger m-4">
              {previewError}
            </div>
          )}
          {!previewLoading && !previewError && (
            <div
              className="crayons-article__body text-styles p-4"
              dangerouslySetInnerHTML={{ __html: previewHTML }}
            />
          )}
        </div>
      ) : (
        <EditorBody
          defaultValue={bodyRef.current}
          onChange={handleChange}
          textAreaId={TEXTAREA_ID}
          textAreaName={textAreaName}
          placeholder={PLACEHOLDER}
          ariaLabel="Page content"
          version="v2"
        />
      )}
    </div>
  );
};

OrgPageEditor.displayName = 'OrgPageEditor';
