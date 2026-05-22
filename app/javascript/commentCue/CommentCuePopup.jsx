import { h } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';

export function CommentCuePopup({ message, closeLabel, onDismiss }) {
  const [leaving, setLeaving] = useState(false);
  const popupRef = useRef(null);

  const beginDismiss = () => setLeaving(true);

  useEffect(() => {
    if (leaving) return undefined;

    const onKey = (e) => {
      if (e.key === 'Escape') beginDismiss();
    };
    const onClick = (e) => {
      if (popupRef.current && !popupRef.current.contains(e.target)) beginDismiss();
    };

    document.addEventListener('keydown', onKey);
    document.addEventListener('mousedown', onClick);

    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('mousedown', onClick);
    };
  }, [leaving]);

  useEffect(() => {
    if (!leaving) return undefined;

    const finish = () => onDismiss();
    popupRef.current.addEventListener('animationend', finish, { once: true });

    return () => popupRef.current.removeEventListener('animationend', finish);
  }, [leaving, onDismiss]);

  return (
    <div
      ref={popupRef}
      class={`comment-cue-popup${leaving ? ' comment-cue-popup--leaving' : ''}`}
      role="status"
      aria-live="polite"
    >
      <p class="comment-cue-popup__message">{message}</p>
      <button
        type="button"
        class="comment-cue-popup__close"
        aria-label={closeLabel}
        onClick={beginDismiss}
      >
        ×
      </button>
    </div>
  );
}
