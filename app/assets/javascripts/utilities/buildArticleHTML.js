/* global timeAgo, filterXSS */

/* eslint-disable no-multi-str */

function buildArticleHTML(article, currentUserId = null) {
  var tagIcon = `<svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg"><path d="M7.784 14l.42-4H4V8h4.415l.525-5h2.011l-.525 5h3.989l.525-5h2.011l-.525 5H20v2h-3.784l-.42 4H20v2h-4.415l-.525 5h-2.011l.525-5H9.585l-.525 5H7.049l.525-5H4v-2h3.784zm2.011 0h3.99l.42-4h-3.99l-.42 4z"/></svg>`;
  if (article && article.class_name === 'Tag') {
    return `<article class="crayons-story">
        <div class="crayons-story__body flex items-start gap-2">
          <span class="radius-default p-2 shrink-0" style="background: ${
            article.bg_color_hex || '#000000'
          }1a; color: ${article.bg_color_hex || '#000'}">
            ${tagIcon}
          </span>
          <div>
            <h3 class="crayons-subtitle-2 lh-tight py-2">
              <a href="/t/${article.name}" class="c-link">
                ${article.name}
              </a>
            </h3>
            ${
              article.short_summary
                ? `<div class="truncate-at-3">${article.short_summary}</div>`
                : ''
            }
          </div>
        </div>
      </article>`;
  }

  if (article && article.class_name === 'PodcastEpisode') {
    return `<article class="crayons-story crayons-podcast-episode mb-2">
        <div class="crayons-story__body flex flex-start">
          <a href="${article.podcast.slug}" class="crayons-podcast-episode__cover">
            <img src="${article.podcast.image_url}" alt="${article.podcast.title}" loading="lazy" />
          </a>
          <div class="pt-2 flex-1">
            <p class="crayons-podcast-episode__author">
              ${article.podcast.title}
            </p>
            <h2 class="crayons-podcast-episode__title crayons-story__title mb-0">
              <a href="${article.path}" id="article-link-${article.id}">
                ${article.podcast.title}
              </a>
            </h2>
          </div>
        </div>
      </article>`;
  }

  if (article) {
    var container = document.getElementById('index-container');

    var flareTag = '';
    var currentTag = '';
    if (container) {
      currentTag = JSON.parse(container.dataset.params).tag;
    }
    if (article.flare_tag && currentTag !== article.flare_tag.name) {
      flareTag = `<a href="/t/${article.flare_tag.name}"
        class="crayons-tag crayons-tag--filled"
        style="--tag-bg: ${article.flare_tag.bg_color_hex}1a; --tag-prefix: ${article.flare_tag.bg_color_hex}; --tag-bg-hover: ${article.flare_tag.bg_color_hex}1a; --tag-prefix-hover: ${article.flare_tag.bg_color_hex};"
      >
        <span class="crayons-tag__prefix">#</span>
        ${article.flare_tag.name}
      </a>`;
    }

    var tagString = '';
    var tagList = article.tag_list || article.cached_tag_list_array || [];
    if (flareTag) {
      tagList = tagList.filter(function (tag) {
        return tag !== article.flare_tag.name;
      });
      tagString += flareTag;
    }
    if (tagList) {
      tagList.forEach(function buildTagString(t) {
        tagString =
          tagString +
          `<a href="/t/${t}" class="crayons-tag crayons-tag--monochrome"><span class="crayons-tag__prefix">#</span>${t}</a>\n`;
      });
    }

    var commentsDisplay = '';
    var commentsCount = '0';
    if ((article.comments_count || '0') > 0) {
      commentsCount = article.comments_count || '0';
    }

    var commentsAriaLabelText = `aria-label="Add a comment to post - ${article.title}"`;

    if (article.class_name !== 'User') {
      commentsDisplay =
        '<a href="' +
        article.path +
        '#comments"' +
        commentsAriaLabelText +
        'class="crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left "><svg class="crayons-icon" width="24" height="24" xmlns="http://www.w3.org/2000/svg"><path d="M10.5 5h3a6 6 0 110 12v2.625c-3.75-1.5-9-3.75-9-8.625a6 6 0 016-6zM12 15.5h1.5a4.501 4.501 0 001.722-8.657A4.5 4.5 0 0013.5 6.5h-3A4.5 4.5 0 006 11c0 2.707 1.846 4.475 6 6.36V15.5z"/></svg>';
      if (commentsCount > 0) {
        commentsDisplay +=
          commentsCount +
          '<span class="hidden s:inline">&nbsp;comments</span></a>';
      } else {
        commentsDisplay +=
          '<span class="hidden s:inline">Add&nbsp;Comment</span></a>';
      }
    }

    var reactionsCount = article.public_reactions_count;
    var reactionsDisplay = '';
    var reactionsText = reactionsCount === 1 ? 'reaction' : 'reactions';

    if (article.class_name !== 'User' && reactionsCount > 0) {
      reactionsDisplay =
        '<a href="' +
        article.path +
        '"' +
        commentsAriaLabelText +
        'class="crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left"><svg class="crayons-icon" width="24" height="24" xmlns="http://www.w3.org/2000/svg"><path d="M18.884 12.595l.01.011L12 19.5l-6.894-6.894.01-.01A4.875 4.875 0 0112 5.73a4.875 4.875 0 016.884 6.865zM6.431 7.037a3.375 3.375 0 000 4.773L12 17.38l5.569-5.569a3.375 3.375 0 10-4.773-4.773L9.613 10.22l-1.06-1.062 2.371-2.372a3.375 3.375 0 00-4.492.25v.001z"/></svg>' +
        reactionsCount +
        `<span class="hidden s:inline">&nbsp;${reactionsText}</span></a>`;
    }

    var picUrl;
    var profileUsername;
    var userName;
    if (article.class_name === 'PodcastEpisode') {
      picUrl = article.main_image;
      profileUsername = article.slug;
      userName = article.title;
    } else {
      picUrl = article.user.profile_image_90;
      profileUsername = article.user.username;
      userName = filterXSS(article.user.name);
    }
    var orgHeadline = '';
    var forOrganization = '';
    var organizationLogo = '';
    var organizationClasses = 'crayons-avatar--l';

    if (
      article.organization &&
      !document.getElementById('organization-article-index')
    ) {
      organizationLogo =
        '<a href="/' +
        article.organization.slug +
        '" class="crayons-logo crayons-logo--l"><img alt="' +
        article.organization.name +
        ' logo" src="' +
        article.organization.profile_image_90 +
        '" class="crayons-logo__image" loading="lazy"/></a>';
      forOrganization =
        '<span><span class="crayons-story__tertiary fw-normal"> for </span><a href="/' +
        article.organization.slug +
        '" class="crayons-story__secondary fw-medium">' +
        article.organization.name +
        '</a></span>';
      organizationClasses =
        'crayons-avatar--s absolute -right-2 -bottom-2 border-solid border-2 border-base-inverted';
    }

    var timeAgoInWords = '';
    if (article.published_at_int) {
      timeAgoInWords = timeAgo({ oldTimeInSeconds: article.published_at_int });
    }

    var publishDate = '';
    if (article.readable_publish_date) {
      if (article.published_timestamp) {
        publishDate =
          '<time datetime="' +
          article.published_timestamp +
          '">' +
          article.readable_publish_date +
          ' ' +
          timeAgoInWords +
          '</time>';
      } else {
        publishDate =
          '<time>' +
          article.readable_publish_date +
          ' ' +
          timeAgoInWords +
          '</time>';
      }
    }

    // We only show profile preview cards for Posts
    var isArticle = article.class_name === 'Article';

    // We need to be able to set the data-info hash attribute with escaped characters.
    // NB: Escaping apostrophes with a "/" does not have the desired effect, as we eventually render the name inside a double quoted string ""
    // To avoid complications with single quotes inside double quotes inside single quotes, we instead replace any apostrophe with its encoded value
    var name = userName.replace(/'/g, '&apos;').replace(/[\\"]/g, '\\$&');

    var previewCardContent = `
      <div id="story-author-preview-content-${article.id}" class="profile-preview-card__content crayons-dropdown p-4 pt-0 branded-7" data-repositioning-dropdown="true" style="border-top-color: var(--card-color);" data-testid="profile-preview-card">
        <div class="gap-4 grid">
          <div class="-mt-4">
            <a href="/${profileUsername}" class="flex">
              <span class="crayons-avatar crayons-avatar--xl mr-2 shrink-0">
                <img src="${picUrl}" class="crayons-avatar__image" alt="" loading="lazy" />
              </span>
              <span class="crayons-link crayons-subtitle-2 mt-5">${userName}</span>
            </a>
          </div>
          <div class="print-hidden">
            <button class="crayons-btn follow-action-button whitespace-nowrap follow-user w-100" data-info='{"id": ${article.user_id}, "className": "User", "style": "full", "name": "${name}"}'>Follow</button>
          </div>
          <div class="author-preview-metadata-container" data-author-id="${article.user_id}"></div>
        </div>
      </div>
    `;

    var meta = `
      <div class="crayons-story__meta">
        <div class="crayons-story__author-pic">
          ${organizationLogo}
          <a href="/${profileUsername}" class="crayons-avatar ${organizationClasses}">
            <img src="${picUrl}" alt="${profileUsername} profile" class="crayons-avatar__image" loading="lazy" />
          </a>
        </div>
        <div>
          <div>
            <a href="/${profileUsername}" class="crayons-story__secondary fw-medium ${
      isArticle ? 'm:hidden' : ''
    }">${userName}</a>
    ${
      isArticle
        ? `<div class="profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:inline-block"><button id="story-author-preview-trigger-${article.id}" aria-controls="story-author-preview-content-${article.id}" class="profile-preview-card__trigger fs-s crayons-btn crayons-btn--ghost p-1 -ml-1 -my-2" aria-label="${userName} profile details">${userName}</button>${previewCardContent}</div>`
        : ''
    }
            ${forOrganization}
          </div>
          <a href="${
            article.path
          }" class="crayons-story__tertiary fs-xs">${publishDate}</a>
        </div>
      </div>
    `;

    var bodyTextSnippet = '';
    var searchSnippetHTML = '';
    if (article.highlight && article.highlight.body_text.length > 0) {
      var firstSnippetChar = article.highlight.body_text[0];
      var startingEllipsis = '';
      if (firstSnippetChar.toLowerCase() !== firstSnippetChar.toUpperCase()) {
        startingEllipsis = '…';
      }
      bodyTextSnippet =
        startingEllipsis + article.highlight.body_text.join('...') + '…';
      if (bodyTextSnippet.length > 0) {
        searchSnippetHTML =
          '<div class="crayons-story__snippet mb-1">' +
          bodyTextSnippet +
          '</div>';
      }
    }

    var readingTimeHTML = '';
    if (article.class_name === 'Article') {
      // we have ` ... || null` for the case article.reading_time is undefined
      readingTimeHTML =
        '<small class="crayons-story__tertiary fs-xs mr-2">' +
        ((article.reading_time || null) < 1
          ? '1 min'
          : article.reading_time + ' min') +
        ' read</small>';
    }

    var saveButton = '';
    var saveSVG =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" role="presentation"><path d="M6.75 4.5h10.5a.75.75 0 01.75.75v14.357a.375.375 0 01-.575.318L12 16.523l-5.426 3.401A.375.375 0 016 19.607V5.25a.75.75 0 01.75-.75zM16.5 6h-9v11.574l4.5-2.82 4.5 2.82V6z" /></svg>';
    var saveFilledSVG =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" role="presentation"><path d="M6.75 4.5h10.5a.75.75 0 01.75.75v14.357a.375.375 0 01-.575.318L12 16.523l-5.426 3.401A.375.375 0 016 19.607V5.25a.75.75 0 01.75-.75z"/></svg>';
    // "!=" instead of "!==" used to compare user_id and currentUserId because
    // currentUserId is a String while user_id is an Integer
    if (article.class_name === 'Article' && article.user_id != currentUserId) {
      saveButton = `
        <button
          type="button"
          id="article-save-button-${article.id}"
          class="c-btn c-btn--icon-alone bookmark-button"
          data-reactable-id="${article.id}"
          data-article-author-id="${article.user_id}"
          aria-label="Save post ${article.title} to reading list">
          <span class="bm-initial">${saveSVG}</span>
          <span class="bm-success">${saveFilledSVG}</span>
        </button>
      `;
    } else if (article.class_name === 'User') {
      saveButton = `
        <button type="button"
          class="crayons-btn crayons-btn--secondary crayons-btn--icon-left fs-s bookmark-button article-engagement-count engage-button follow-action-button follow-user"
          data-info='{"id": ${article.id},"className":"User", "name": "${userName}"}'
        data-follow-action-button>
          &nbsp;
        </button>`;
    }

    var videoHTML = '';
    if (article.cloudinary_video_url) {
      videoHTML =
        '<a href="' +
        article.path +
        '" class="crayons-story__video" style="background-image:url(' +
        article.cloudinary_video_url +
        ')"><div class="crayons-story__video__time">' +
        (article.video_duration_string || article.video_duration_in_minutes) +
        '</div></a>';
    }

    var navigationLink = `
      <a
        href="${article.path}"
        aria-labelledby="article-link-${article.id}"
        class="crayons-story__hidden-navigation-link"
      >
        ${filterXSS(article.title)}
      </a>
    `;

    return `<article class="crayons-story"
      data-article-path="${article.path}"
      id="article-${article.id}"
      data-content-user-id="${article.user_id}">\
        ${navigationLink}\
        <div role="presentation">\
          ${videoHTML}\
          <div class="crayons-story__body">\
            <div class="crayons-story__top">\
              ${meta}
            </div>\
            <div class="crayons-story__indention">
              <h3 class="crayons-story__title">
                <a href="${article.path}" id="article-link-${article.id}">
                  ${filterXSS(article.title)}
                </a>
              </h3>\
              <div class="crayons-story__tags">
                ${tagString}
              </div>\
              ${searchSnippetHTML}\
              <div class="crayons-story__bottom">\
                <div class="crayons-story__details">
                  ${reactionsDisplay} ${commentsDisplay}
                </div>\
                <div class="crayons-story__save">\
                  ${readingTimeHTML}\
                  ${saveButton}
                </div>\
              </div>\
            </div>\
          </div>\
        </div>\
      </article>`;
  }

  return '';
}

/* eslint-enable no-multi-str */
