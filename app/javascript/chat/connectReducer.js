export function connectReducer(state, action) {
  const { type, payload = {} } = action;

  switch (type) {
    case 'closeDeleteModal':
      return {
        ...state,
        showDeleteModal: payload.showDeleteModal,
        messageDeleteId: null,
      };
    default:
      return state;
  }
}
