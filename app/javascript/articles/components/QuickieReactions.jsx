import { h } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';
import { locale } from '../../utilities/locale';

/* global sendFetch, getCsrfToken, showLoginModal, sendHapticMessage, userData */

const DEFAULT_REACTION_CATEGORIES = [
  { slug: 'like', name: 'Like' },
  { slug: 'unicorn', name: 'Unicorn' },
  { slug: 'exploding_head', name: 'Exploding Head' },
  { slug: 'raised_hands', name: 'Raised Hands' },
  { slug: 'fire', name: 'Fire' },
];

function getAvailableReactions() {
  const resourcesContainer = document.getElementById(
    'reaction-category-resources',
  );
  if (!resourcesContainer) {
    return DEFAULT_REACTION_CATEGORIES.map((cat) => ({
      ...cat,
      src: `/assets/${cat.slug}.svg`,
    }));
  }

  const imgs = Array.from(resourcesContainer.querySelectorAll('img[data-slug]'));
  if (imgs.length === 0) {
    return DEFAULT_REACTION_CATEGORIES.map((cat) => ({
      ...cat,
      src: `/assets/${cat.slug}.svg`,
    }));
  }

  return imgs
    .sort(
      (a, b) =>
        Number(a.dataset.position || 99) - Number(b.dataset.position || 99),
    )
    .map((img) => ({
      slug: img.dataset.slug,
      name: img.dataset.name || img.dataset.slug,
      src: img.src,
    }));
}

export const QuickieReactions = ({ article, currentUserId }) => {
  const [totalReactions, setTotalReactions] = useState(
    article.public_reactions_count || 0,
  );
  const [reactionCategories, setReactionCategories] = useState(
    article.public_reaction_categories || [],
  );
  const [selectedSlugs, setSelectedSlugs] = useState(() => new Set());
  const [isPickerOpen, setIsPickerOpen] = useState(false);
  const closeTimeoutRef = useRef(null);

  useEffect(() => {
    setTotalReactions(article.public_reactions_count || 0);
    setReactionCategories(article.public_reaction_categories || []);
  }, [article.id, article.public_reactions_count, article.public_reaction_categories]);

  useEffect(() => {
    return () => {
      if (closeTimeoutRef.current) {
        clearTimeout(closeTimeoutRef.current);
      }
    };
  }, []);

  const availableReactions = getAvailableReactions();

  const clearCloseTimer = () => {
    if (closeTimeoutRef.current) {
      clearTimeout(closeTimeoutRef.current);
      closeTimeoutRef.current = null;
    }
  };

  const handleMouseEnter = () => {
    clearCloseTimer();
    setIsPickerOpen(true);
  };

  const handleMouseLeave = () => {
    clearCloseTimer();
    closeTimeoutRef.current = setTimeout(() => {
      setIsPickerOpen(false);
    }, 180);
  };

  const isUserSignedIn = () => {
    if (document.body?.dataset?.userStatus === 'logged-out') {
      return false;
    }
    if (currentUserId || article.current_user_signed_in) {
      return true;
    }
    if (typeof userData === 'function' && userData()) {
      return true;
    }
    return Boolean(document.body?.dataset?.user);
  };

  const toggleReaction = async (slug, name) => {
    if (typeof sendHapticMessage === 'function') {
      sendHapticMessage('medium');
    }

    if (!isUserSignedIn()) {
      if (typeof showLoginModal === 'function') {
        showLoginModal({
          referring_source: 'post_index_toolbar',
          trigger: 'reaction',
        });
      }
      return;
    }

    const wasSelected = selectedSlugs.has(slug);
    const nextSelected = new Set(selectedSlugs);
    if (wasSelected) {
      nextSelected.delete(slug);
    } else {
      nextSelected.add(slug);
    }
    setSelectedSlugs(nextSelected);

    const delta = wasSelected ? -1 : 1;
    setTotalReactions((prev) => Math.max(0, prev + delta));

    if (!wasSelected) {
      setReactionCategories((prev) => {
        if (prev.some((cat) => cat.slug === slug)) {
          return prev;
        }
        return [...prev, { slug, name }];
      });
    }

    try {
      const formData = new FormData();
      formData.append('reactable_type', 'Article');
      formData.append('reactable_id', String(article.id));
      formData.append('category', slug);

      const csrfToken =
        typeof getCsrfToken === 'function'
          ? await getCsrfToken()
          : window.csrfToken || 'csrf-token';

      if (!csrfToken || typeof sendFetch !== 'function') {
        return;
      }

      const fetchCallback = sendFetch('reaction-creation', formData);
      const response = await fetchCallback(csrfToken);
      if (response && response.status === 200 && typeof response.json === 'function') {
        const json = await response.json();
        if (!wasSelected && json.result === 'destroy') {
          // User had already reacted prior to page load; reconcile state
          setSelectedSlugs((prev) => {
            const reconciled = new Set(prev);
            reconciled.delete(slug);
            return reconciled;
          });
          setTotalReactions((prev) => Math.max(0, prev - 2));
        } else if (wasSelected && json.result === 'create') {
          setSelectedSlugs((prev) => new Set(prev).add(slug));
          setTotalReactions((prev) => prev + 2);
        }
      }
    } catch (_error) {
      // Revert optimistic update on network failure
      setSelectedSlugs((prev) => {
        const reverted = new Set(prev);
        if (wasSelected) {
          reverted.add(slug);
        } else {
          reverted.delete(slug);
        }
        return reverted;
      });
      setTotalReactions((prev) => Math.max(0, prev - delta));
    }
  };

  const renderReactionIcons = () => {
    const reactionIconsContainer = document.getElementById(
      'reaction-category-resources',
    );

    if (!reactionCategories || reactionCategories.length === 0) {
      return (
        <span className="quickie-reactions__empty-icon" aria-hidden="true">
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            className="crayons-icon"
          >
            <path d="M12.001 4.529c2.349-2.109 5.979-2.039 8.242.228 2.262 2.268 2.34 5.88.236 8.236l-8.48 8.492-8.478-8.492c-2.104-2.356-2.025-5.974.236-8.236 2.265-2.264 5.888-2.34 8.244-.228zm6.826 1.641c-1.5-1.502-3.92-1.563-5.49-.153l-1.335 1.198-1.336-1.197c-1.575-1.412-3.99-1.35-5.494.154-1.49 1.49-1.565 3.875-.192 5.451L12 18.654l7.02-7.03c1.374-1.577 1.299-3.959-.193-5.454z" />
          </svg>
        </span>
      );
    }

    const icons = reactionCategories
      .slice()
      .reverse()
      .map((category) => {
        const matchedImg = reactionIconsContainer?.querySelector(
          `img[data-slug=${category.slug}]`,
        );
        const path =
          matchedImg?.src ||
          availableReactions.find((r) => r.slug === category.slug)?.src ||
          `/assets/${category.slug}.svg`;
        const alt = category.name || category.slug;
        return (
          <span className="crayons_icon_container" key={category.slug}>
            <img src={path} width="18" height="18" alt={alt} />
          </span>
        );
      });

    return (
      <span
        className="multiple_reactions_icons_container"
        dir="rtl"
        data-testid="multiple-reactions-icons-container"
      >
        {icons}
      </span>
    );
  };

  const renderReactionLabel = () => {
    if (totalReactions === 0) {
      return (
        <span className="aggregate_reactions_counter">
          <span className="hidden s:inline">
            {locale('core.react') || 'React'}
          </span>
        </span>
      );
    }

    const reactionNoun =
      totalReactions === 1
        ? locale('core.reaction') || 'reaction'
        : `${locale('core.reaction') || 'reaction'}s`;

    return (
      <span className="aggregate_reactions_counter">
        <span className="hidden s:inline" title="Number of reactions">
          {totalReactions}&nbsp;{reactionNoun}
        </span>
        <span className="inline s:hidden">{totalReactions}</span>
      </span>
    );
  };

  const hasUserReacted = selectedSlugs.size > 0;
  const primaryReaction = availableReactions[0] || {
    slug: 'like',
    name: 'Like',
  };

  return (
    <div
      className="quickie-reactions"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onClick={(event) => event.stopPropagation()}
      role="presentation"
    >
      {isPickerOpen && (
        <div
          className="quickie-reaction-picker"
          role="toolbar"
          aria-label="React to this quickie"
          data-testid="quickie-reaction-picker"
        >
          {availableReactions.map((reaction) => {
            const isSelected = selectedSlugs.has(reaction.slug);
            return (
              <button
                key={reaction.slug}
                type="button"
                className={`quickie-reaction-picker__btn${
                  isSelected ? ' is-selected' : ''
                }`}
                onClick={(event) => {
                  event.preventDefault();
                  event.stopPropagation();
                  toggleReaction(reaction.slug, reaction.name);
                }}
                aria-label={`React with ${reaction.name}`}
                aria-pressed={isSelected}
                title={reaction.name}
                data-testid={`quickie-react-${reaction.slug}`}
              >
                <img
                  src={reaction.src}
                  width="22"
                  height="22"
                  alt={reaction.name}
                />
              </button>
            );
          })}
        </div>
      )}

      <button
        type="button"
        className={`crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left quickie-reactions__trigger${
          hasUserReacted ? ' is-reacted' : ''
        }`}
        data-reaction-count
        data-reactable-id={article.id}
        data-testid="quickie-reaction-button"
        aria-label={`React to quickie - ${article.title_for_metadata || article.title}`}
        aria-pressed={hasUserReacted}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          toggleReaction(primaryReaction.slug, primaryReaction.name);
        }}
      >
        <div className="multiple_reactions_aggregate">
          {renderReactionIcons()}
          {renderReactionLabel()}
        </div>
      </button>
    </div>
  );
};

QuickieReactions.propTypes = {
  article: articlePropTypes.isRequired,
  currentUserId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
};

QuickieReactions.displayName = 'QuickieReactions';
