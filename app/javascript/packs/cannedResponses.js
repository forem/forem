// import initCannedResponses from '../cannedResponses/cannedResponses'
import initModeratorResponses from '../cannedResponses/moderatorResponses';

window.InstantClick.on('change', () => {
  initModeratorResponses();
});

initModeratorResponses();
