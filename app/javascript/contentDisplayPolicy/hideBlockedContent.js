/* global userData */

export default function hideBlockedContent() {
  const contentUserElements = Array.from(
    document.querySelectorAll('div[data-content-user-id]'),
  );
  const user = userData(); //global var
  const blockedUserIds = user ? user.blocked_user_ids : [];

  const divsToHide = contentUserElements.filter((div) => {
    const { contentUserId } = div.dataset;
    return blockedUserIds.includes(parseInt(contentUserId, 10));
  });

  divsToHide.forEach((div) => {
    if (div.className.includes('crayons-story')) {
      div.style.display = 'none';
    } else if (div.className.includes('single-comment-node')) {
      const divInnerComment = div.getElementsByClassName('inner-comment')[0];
      divInnerComment.innerHTML = `
        <div class="body " style="padding-bottom:32px;opacity:0.3;user-select:none;cursor:default">
          [blocked content]
        </div>
      `;
    }
  });
}

window.addEventListener('checkBlockedContent', hideBlockedContent);
