# Contributing to Photo Organizer

Thank you for your interest in contributing to Photo Organizer! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project.

## How to Contribute

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Make your changes
4. Run shellcheck to ensure code quality
5. Test your changes
6. Submit a pull request

## Development Environment Setup

1. Ensure you have `bash` and `exiftool` installed
2. Clone the repository
3. Make the script executable: `chmod +x photo_organizer.sh`

## Code Style Guidelines

- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use snake_case for variables and functions
- Use 2-space indentation
- Keep lines to a maximum of 80 characters
- Add comments for complex operations
- Include proper error handling

## Testing

Before submitting a pull request, please:

1. Run shellcheck: `shellcheck photo_organizer.sh`
2. Test your changes with various input files and options
3. If adding new functionality, add appropriate test cases to the `test_scripts` directory

## Pull Request Process

1. Update the README.md with details of changes if appropriate
2. The pull request will be merged once it has been reviewed and approved

## Feature Requests and Bug Reports

Please use the GitHub issue tracker to submit feature requests and bug reports.

Thank you for your contributions!