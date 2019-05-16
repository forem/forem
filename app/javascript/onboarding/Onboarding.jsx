import 'preact/devtools';
import WelcomeSlide from './components/WelcomeSlide';
import { h, Component } from 'preact';

export default class Onboarding extends Component {
  constructor(props) {
    super(props);

    this.nextSlide = this.nextSlide.bind(this);
    this.slides = [<WelcomeSlide />];

    this.state = {
      currentSlide: 0,
    };
  }

  nextSlide() {
    let nextSlide = this.state.currentSlide + 1;
    if (nextSlide < this.slides.length)
      this.setState({
        currentSlide: nextSlide,
      });
  }

  prevSlide() {
    let prevSlide = this.state.currentSlide - 1;
    if (prevSlide > 0) {
      this.setState({
        currentSlide: prevSlide,
      });
    }
  }

  render() {
    return (
      <div>
        {this.slides[this.state.currentSlide]}
        <button onClick={this.prevSlide}>BACK</button>
        <button onClick={this.nextSlide}>NEXT</button>
      </div>
    );
  }
}
