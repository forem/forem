import { h, render, Component } from 'preact';

// page 1
const OnboardingWelcome = () => {
  const messages = [
    'Thank you for joining the DEV Community.',
    'Keep up with the people and software trends you care about. ❤️',
  ];

  const specialMessage = "Let's get started!";

  return (
    <div className="onboarding-initial-welcome">
      {messages.map(item => (
        <p>{item}</p>
      ))}
      <p>
        <em>
          <strong className="green">{specialMessage}</strong>
        </em>
      </p>
    </div>
  );
};

export default OnboardingWelcome;
