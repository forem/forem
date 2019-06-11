import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import { ListingDashboard } from '../listingDashboard';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
const l = [{id:23,bumped_at:"2019-06-11T16:45:37.229Z",category:"cfp",organization_id:null,slug:"asdfasdf-2ea8",title:"asdfasdf",updated_at:"2019-06-11T16:45:37.237Z",user_id:11,tag_list:["computerscience","career"],author:{name:"MarioSee",username:"mariocsee",profile_image_90:"/uploads/user/profile_image/11/e594d777-b57b-41d6-a793-5d8127bd11b3.jpeg"}},{id:24,bumped_at:"2019-06-11T16:59:16.312Z",category:"events",organization_id:2,slug:"yoyoyoyoyoooooooo-4jcb",title:"YOYOYOYOYOOOOOOOO",updated_at:"2019-06-11T16:59:16.316Z",user_id:11,tag_list:["computerscience","conference","career"],author:{name:"Yoyodyne",username:"org3737",profile_image_90:"/uploads/organization/profile_image/2/5edb1e49-bea9-4e99-bc32-acc10c52a935.png"}},{id:25,bumped_at:"2019-06-11T17:01:25.143Z",category:"cfp",organization_id:3,slug:"hehhehe-5hld",title:"hehhehe",updated_at:"2019-06-11T17:01:25.169Z",user_id:11,tag_list:[],author:{name:"Infotrode",username:"org5254",profile_image_90:"/uploads/organization/profile_image/3/04d4e1f1-c2e0-4147-81e2-bc8a2657296b.png"}}];
global.document.body.innerHTML = `<div id="classifieds-listings-dashboard" data-listings=${JSON.stringify(l)} data-usercredits="3" data-orglistings=${JSON.stringify([{id:24,bumped_at:"2019-06-11T16:59:16.312Z",category:"events",organization_id:2,slug:"yoyoyoyoyoooooooo-4jcb",title:"YOYOYOYOYOOOOOOOO",updated_at:"2019-06-11T16:59:16.316Z",user_id:11,tag_list:["computerscience","conference","career"],author:{name:"Yoyodyne",username:"org3737",profile_image_90:"/uploads/organization/profile_image/2/5edb1e49-bea9-4e99-bc32-acc10c52a935.png"}},{id:25,bumped_at:"2019-06-11T17:01:25.143Z",category:"cfp",organization_id:3,slug:"hehhehe-5hld",title:"hehhehe",updated_at:"2019-06-11T17:01:25.169Z",user_id:11,tag_list:[],author:{name:"Infotrode",username:"org5254",profile_image_90:"/uploads/organization/profile_image/3/04d4e1f1-c2e0-4147-81e2-bc8a2657296b.png"}}])} data-orgs=${JSON.stringify([{id:2,name:"Yoyodyne",slug:"org3737",unspent_credits_count:1},{id:3,name:"Infotrode",slug:"org5254",unspent_credits_count:1}])} ></div>`;
global.window = doc.defaultView;

describe('<ListingDashboard />', () => {
  it('should load listing dashboard', () => {
    const tree = deep(<ListingDashboard />);
    expect(tree).toMatchSnapshot();
  })

  describe('should load the following elements, attributes and values', () => {
    const context = deep(<ListingDashboard />);
    expect(context.component()).toBeInstanceOf(ListingDashboard);
    context.setState({ listings:
        [ { id: 23,
            bumped_at: '2019-06-11T16:45:37.229Z',
            category: 'cfp',
            organization_id: null,
            slug: 'asdfasdf-2ea8',
            title: 'asdfasdf',
            updated_at: '2019-06-11T16:45:37.237Z',
            user_id: 11,
            tag_list: [Array],
            author: [Object] },
          { id: 24,
            bumped_at: '2019-06-11T16:59:16.312Z',
            category: 'events',
            organization_id: 2,
            slug: 'yoyoyoyoyoooooooo-4jcb',
            title: 'YOYOYOYOYOOOOOOOO',
            updated_at: '2019-06-11T16:59:16.316Z',
            user_id: 11,
            tag_list: [Array],
            author: [Object] },
          { id: 25,
            bumped_at: '2019-06-11T17:01:25.143Z',
            category: 'cfp',
            organization_id: 3,
            slug: 'hehhehe-5hld',
            title: 'hehhehe',
            updated_at: '2019-06-11T17:01:25.169Z',
            user_id: 11,
            tag_list: [],
            author: [Object] } ],
       orgListings:
        [ { id: 24,
            bumped_at: '2019-06-11T16:59:16.312Z',
            category: 'events',
            organization_id: 2,
            slug: 'yoyoyoyoyoooooooo-4jcb',
            title: 'YOYOYOYOYOOOOOOOO',
            updated_at: '2019-06-11T16:59:16.316Z',
            user_id: 11,
            tag_list: [Array],
            author: [Object] },
          { id: 25,
            bumped_at: '2019-06-11T17:01:25.143Z',
            category: 'cfp',
            organization_id: 3,
            slug: 'hehhehe-5hld',
            title: 'hehhehe',
            updated_at: '2019-06-11T17:01:25.169Z',
            user_id: 11,
            tag_list: [],
            author: [Object] } ],
       orgs:
        [ { id: 2,
            name: 'Yoyodyne',
            slug: 'org3737',
            unspent_credits_count: 1 },
          { id: 3,
            name: 'Infotrode',
            slug: 'org5254',
            unspent_credits_count: 1 } ],
       userCredits: '3',
       selectedListings: 'user' });
    context.rerender()

    it('for user and org buttons', () => {
        console.log(context.text())
      

    }) 
  })
})