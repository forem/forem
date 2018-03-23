import { h, render, Component } from 'preact';
import OnboardingSingleTag from './OnboardingSingleTag';

// page 2
class OnboardingTags extends Component {
  constructor(props) {
    super(props);
  }
  render() {
    const tags = this.props.allTags.map((tag) => {
      return (
        <OnboardingSingleTag key={tag.id} tag={tag} onTagClick={this.props.handleFollowTag.bind(this, tag)} />
      );
    });

    return (
      <div className="tags-slide">
        <p>
          <strong class="yellow">What topics are you interested in?</strong> Here are a few tags to follow (There are plenty more you can choose from at any time)
        </p>
        <div className="tags-col-container">
            {tags}
        </div>
      </div>
    );
  }
}

export default OnboardingTags;
