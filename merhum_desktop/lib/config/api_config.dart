const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  // Docker Compose: port 5000 | lokalno (VS): port 5100
  defaultValue: 'http://localhost:5000',
);
