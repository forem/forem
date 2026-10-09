import { processPayload } from '../actions';

describe('processPayload', () => {
  const basePayload = {
    title: 'My Article',
    body_markdown: '# Hello World',
    tag_list: 'javascript, testing',
    organizationId: 42,
    coAuthorIdsList: '1,2',
  };

  const uiOnlyFields = {
    previewShowing: true,
    helpShowing: false,
    previewResponse: '<p>preview html</p>',
    helpHTML: '<p>help html</p>',
    imageManagementShowing: false,
    moreConfigShowing: true,
    errors: { title: ['is too short'] },
    organizations: [
      { id: 1, name: 'Org One', fetch_users_url: '/api/users?org=1' },
      { id: 2, name: 'Org Two', fetch_users_url: '/api/users?org=2' },
    ],
    authorId: 99,
    coAuthorsData: [
      { id: 1, name: 'Co Author', username: 'coauthor' },
    ],
  };

  it('preserves article content fields in the output', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result.title).toEqual('My Article');
    expect(result.body_markdown).toEqual('# Hello World');
    expect(result.tag_list).toEqual('javascript, testing');
    expect(result.organizationId).toEqual(42);
    expect(result.coAuthorIdsList).toEqual('1,2');
  });

  it('strips preview and help UI state fields', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result).not.toHaveProperty('previewShowing');
    expect(result).not.toHaveProperty('helpShowing');
    expect(result).not.toHaveProperty('previewResponse');
    expect(result).not.toHaveProperty('helpHTML');
  });

  it('strips modal/config UI state fields', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result).not.toHaveProperty('imageManagementShowing');
    expect(result).not.toHaveProperty('moreConfigShowing');
    expect(result).not.toHaveProperty('errors');
  });

  it('strips organizations array to prevent payload bloat', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result).not.toHaveProperty('organizations');
  });

  it('strips authorId which is UI-only context', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result).not.toHaveProperty('authorId');
  });

  it('strips coAuthorsData resolved user objects', () => {
    const result = processPayload({ ...basePayload, ...uiOnlyFields });

    expect(result).not.toHaveProperty('coAuthorsData');
  });

  describe('co-author invitations', () => {
    const invitationFields = {
      coAuthorInvitationsEnabled: true,
      coAuthorInvitationsMax: 4,
      coAuthorInvitations: [
        { id: 10, status: 'pending', user: { id: 7, username: 'ada' } },
      ],
      coAuthorInvitees: [
        { id: 7, username: 'ada' },
        { id: 8, username: 'grace' },
      ],
    };

    it('sends the invitee ids for a personal post', () => {
      const result = processPayload({
        ...basePayload,
        ...invitationFields,
        organizationId: null,
      });

      expect(result.coAuthorInviteeIds).toEqual([7, 8]);
    });

    it('sends an empty list when every invitee was removed', () => {
      const result = processPayload({
        ...basePayload,
        ...invitationFields,
        organizationId: '',
        coAuthorInvitees: [],
      });

      expect(result.coAuthorInviteeIds).toEqual([]);
    });

    it('leaves the list out for an organization post', () => {
      const result = processPayload({ ...basePayload, ...invitationFields });

      expect(result).not.toHaveProperty('coAuthorInviteeIds');
    });

    it('leaves the list out when invitations are disabled', () => {
      const result = processPayload({
        ...basePayload,
        ...invitationFields,
        organizationId: null,
        coAuthorInvitationsEnabled: false,
      });

      expect(result).not.toHaveProperty('coAuthorInviteeIds');
    });

    it('strips the invitation UI state', () => {
      const result = processPayload({
        ...basePayload,
        ...invitationFields,
        organizationId: null,
      });

      expect(result).not.toHaveProperty('coAuthorInvitationsEnabled');
      expect(result).not.toHaveProperty('coAuthorInvitationsMax');
      expect(result).not.toHaveProperty('coAuthorInvitations');
      expect(result).not.toHaveProperty('coAuthorInvitees');
    });
  });

  it('returns an empty-ish object when given only UI fields', () => {
    const result = processPayload(uiOnlyFields);

    // All UI-only keys should be gone
    const keys = Object.keys(result);
    const uiKeys = Object.keys(uiOnlyFields);
    uiKeys.forEach((key) => {
      expect(keys).not.toContain(key);
    });
  });

  it('handles a payload with none of the excluded fields present', () => {
    const result = processPayload({ ...basePayload });

    expect(result).toEqual(basePayload);
  });
});
