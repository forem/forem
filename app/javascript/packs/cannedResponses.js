import initCannedResponses from '../cannedResponses/cannedResponses'

window.InstantClick.on('change', () => {
  initCannedResponses();
});

initCannedResponses();
