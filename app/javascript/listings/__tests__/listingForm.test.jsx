import { h } from 'preact';
import { deep, shallow } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import ListingForm from '../listingForm';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.document.body = ` 
<body data-user-status="logged-in" 
  data-pusher-key="5bcdbcc8dd2763f1d538" 
  class="default default-article-body pro-status-false" 
  data-user=${JSON.stringify(
    {'id':11,
    'name':'Mario See',
    'username':'mariocsee',
    'profile_image_90':'/uploads/user/profile_image/11/08f6aa82-3fc4-44dd-acc4-317ca694f48a.jpeg',
    'followed_tag_names':[],
    'followed_tags':'[]',
    'followed_user_ids':[9,5,8,2,4,6,7,1,3,10],
    'followed_organization_ids':[],
    'followed_podcast_ids':[],
    'reading_list_ids':[],
    'saw_onboarding':true,
    'checked_code_of_conduct':true,
    'checked_terms_and_conditions':true,
    'number_of_comments':0,
    'display_sponsors':true,
    'trusted':false,
    'experience_level':null,
    'preferred_languages_array':['en'],
    'config_body_class':'default default-article-body pro-status-false',
    'onboarding_variant_version':'6',
    'pro':false
  })}
  data-loaded="true">
</body>`;
global.window = doc.defaultView;

const organizations = '{}';
const listing = '{}';
const categoriesForSelect = '[]';
const categoriesForDetails = '[]';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.document.body.innerHTML = ``;
global.window = doc.defaultView;

describe('<ListingForm />', () => {
  it('should load listingForm', () => {
    const tree = deep(
      <ListingForm
        organizations={organizations}
        listing={listing}
        categoriesForSelect={categoriesForSelect}
        categoriesForDetails={categoriesForDetails}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
