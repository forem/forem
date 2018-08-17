import { h } from 'preact';

const OnboardingWelcomeThread = () => {
  const wrapInYellow = message => <strong className="yellow">{message}</strong>;

  return (
    <div>
      <p>Got a question? {wrapInYellow('Start a discussion')}.</p>
      <p>Got a blog post? {wrapInYellow('Publish it')}.</p>
      <p>
        Not sure what to say? {wrapInYellow('Fill out your profile')} or just
        poke around and read.
      </p>
      <p>
        Like something you read? {wrapInYellow('Follow the author')} for more
        from them.
      </p>
      <p>
        See you around!{' '}
        <span role="img" aria-label="Victory hand">
          ✌️
        </span>{' '}
      </p>
    </div>
  );
};

export default OnboardingWelcomeThread;
