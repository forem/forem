// /* global InstantClick */

// 'use strict';

// function selectNavigation(select, urlPrefix) {
//   const trigger = document.getElementById(select);

//   if (trigger) {
//     trigger.addEventListener('change', (event) => {
//       let url = event.target.value;
//       if (urlPrefix) {
//         url = urlPrefix + url;
//       }

//       InstantClick.preload(url);
//       InstantClick.display(url);
//     });
//   }
// }

// function initializeDashboardSort() {
//   console.log('assets sort initializing');
//   selectNavigation('dashboard_sort', '/dashboard?sort=');
//   selectNavigation('dashboard_author');
//   selectNavigation('mobile_nav_dashboard');
// }
