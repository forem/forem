import { h } from 'preact';

export const CommentsList = () => (
  <div className="crayons-story__comments">
    <p className="crayons-story__comments__headline">Top comments:</p>

    <div className="crayons-comment pl-2">
      <div className="crayons-comment__meta">
        <a href="#" className="crayons-story__secondary fw-medium">
          <span className="crayons-avatar mr-2"><img src="https://placehold.it/32" className="crayons-avatar__image" alt="Ben" /></span>
          nickityonline71
        </a>
        <a href="#" className="crayons-story__tertiary ml-1">5 mins ago</a>
      </div>
      <div className="crayons-comment__body">Default font is set to 16px (fs-base). It should be standard in UI. Smaller and bigger font sizes should be <a href="#">used</a> carefully with respect to good visual rythm between elements. Medium should be used to emphasize something but not make it as loud as Bold.</div>
    </div>
    
    <div className="crayons-story__comments__actions">
      <a href="#" className="crayons-btn crayons-btn--secondary fs-s">See all 7 comments</a>
      <button className="crayons-btn crayons-btn--secondary fs-s" type="button">Subscribe</button>
    </div>
  </div>
);

CommentsList.displayName = 'CommentsList';
