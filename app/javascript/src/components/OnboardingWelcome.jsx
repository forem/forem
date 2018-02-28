import { h, render, Component } from 'preact';

// page 1
const OnboardingWelcome = () => {
  const messages = [
    "Hi there, I'm Sloan. It's nice to meet you!",
    "Welcome to the community. It's a place to talk shop and keep up with other devs.",
    "Share more, learn more, write better code; I think you'll like it here. 🐨",
  ];

  const specialMessage = "Let's get started";

  return (
    <div>
      {messages.map(item => (<p>{item}</p>))}
      <p><strong className="yellow">{specialMessage}</strong>.</p>
    </div>
  );
};

export default OnboardingWelcome;
