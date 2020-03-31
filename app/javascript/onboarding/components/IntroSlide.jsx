import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import SlideContent from './SlideContent';
import { updateOnboarding } from '../utilities';

class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.onSubmit = this.onSubmit.bind(this);
  }

  componentDidMount() {
    updateOnboarding('intro slide');
  }

  onSubmit() {
    const { next } = this.props;
    next();
  }

  selectVariant(variantId) {
    this.defaultVariant = (
      <div>
        <p>
          DEV is where programmers share ideas and help each other grow.
          <span role="img" aria-label="Nerd Face">
            🤓
          </span>
        </p>
        <p>
          Ask questions, leave helpful comments, encourage others, and have fun!
          <span role="img" aria-label="Raising Hands">
            🙌
          </span>
        </p>
        <p>
          A few 
          {' '}
          <strong>quick questions</strong>
          {' '}
          for you before you get
          started...
        </p>
      </div>
    );
    const variants = [
      <SlideContent
        imageSource="https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif"
        imageAlt="hello cat"
      />,
      <SlideContent
        imageSource="https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif"
        imageAlt="hello cat"
        content={<p>We have a few quick questions to fill out your profile</p>}
      />,
      <SlideContent
        imageSource="https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif"
        imageAlt="hello"
        content={(
          <p>
            The more you get involved in community, the better developer you
            will be.
          </p>
        )}
        style={{ textAlign: 'center', fontSize: '0.9em' }}
      />,
      <SlideContent
        imageSource="https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif"
        imageAlt="hello"
        content={<p>You just made a great choice for your dev career.</p>}
        style={{ textAlign: 'center', fontSize: '1.1em' }}
      />,
    ];
    return variants[variantId - 1] || this.defaultVariant;
  }

  render() {
    const { prev } = this.props;

    return (
      <div className="onboarding-main introduction">
        <div className="onboarding-content">
          <figure>
            <img
              src="/assets/purple-dev-logo.png"
              className="sticker-logo"
              alt="DEV"
            />
          </figure>
          <h1 className="introduction-title">Welcome to DEV!</h1>
          <h2 className="introduction-subtitle">
            DEV is where programmers share ideas and help each other grow.
          </h2>
        </div>
        <Navigation prev={prev} next={this.onSubmit} hidePrev />
      </div>
    );
  }
}

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default IntroSlide;
