function backfillLinkTarget() {
  const links = document.getElementById('page-content').querySelectorAll('a[href]');
  const appDomain = window.location.hostname;

  links.forEach((link) => {
    const href = link.getAttribute('href');

    if (href && (href.startsWith('http://') || href.startsWith('https://')) && !href.includes(appDomain)) {
      link.setAttribute('target', '_blank');
      
      const existingRel = link.getAttribute('rel');
      const newRelValues = ["noopener", "noreferrer"];

      if (existingRel) {
        const existingRelValues = existingRel.split(" ");
        const mergedRelValues = [...new Set([...existingRelValues, ...newRelValues])].join(" ");
        link.setAttribute('rel', mergedRelValues);
      } else {
        link.setAttribute('rel', newRelValues.join(" "));
      }
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  backfillLinkTarget();
});
