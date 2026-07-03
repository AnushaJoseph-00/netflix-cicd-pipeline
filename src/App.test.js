import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders without crashing', () => {
  render(<App />);
});

test('renders the Netflix Originals row', () => {
  render(<App />);
  expect(screen.getByText('Netflix Originals')).toBeInTheDocument();
});

test('renders banner play button', () => {
  render(<App />);
  expect(screen.getByText('Play')).toBeInTheDocument();
});