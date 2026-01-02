# Contributing to vagrant-orbstack-provider

Thank you for your interest in contributing to vagrant-orbstack-provider! This guide will help you understand our development process and how to submit contributions effectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Commit Message Convention](#commit-message-convention)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Code of Conduct](#code-of-conduct)
- [Questions & Resources](#questions--resources)

## Getting Started

We welcome contributions from the community! Whether you're fixing a bug, adding a feature, or improving documentation, your help is appreciated.

Before you begin:
1. Check existing [issues](https://github.com/spiralhouse/vagrant-orbstack-provider/issues) and [pull requests](https://github.com/spiralhouse/vagrant-orbstack-provider/pulls) to avoid duplication
2. For major changes, open an issue first to discuss your approach
3. Read this guide to understand our conventions

## Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) to automatically generate changelogs and determine version bumps. Understanding this format is crucial for contributing.

### Format

```
<type>: <description> [optional Linear issue]

[optional body]

[optional footer]
```

### Types and Version Impact

| Type | Version Bump | When to Use | Changelog Section |
|------|-------------|-------------|-------------------|
| `feat` | **MINOR** (0.1.0 → 0.2.0) | New features or capabilities | **Added** |
| `fix` | **PATCH** (0.1.0 → 0.1.1) | Bug fixes | **Fixed** |
| `docs` | **PATCH** (0.1.0 → 0.1.1) | Documentation-only changes | **Documentation** |
| `refactor` | **PATCH** (0.1.0 → 0.1.1) | Code refactoring (no behavior change) | **Changed** |
| `test` | **PATCH** (0.1.0 → 0.1.1) | Adding or updating tests | (hidden from changelog) |
| `chore` | **PATCH** (0.1.0 → 0.1.1) | Maintenance, dependencies, tooling | (hidden from changelog) |

**Note**: This project is currently pre-1.0, so `feat` commits trigger MINOR version bumps (0.x.0). Breaking changes are not expected until 1.0.0 release.

**Breaking Changes**: To trigger a MAJOR version bump (1.0.0 → 2.0.0), add `BREAKING CHANGE:` in the commit footer:

```
feat: redesign configuration API

BREAKING CHANGE: The `distro` configuration attribute has been renamed to `distribution`.
Users must update their Vagrantfiles to use the new attribute name.
```

### Examples

**Feature with Linear issue reference:**
```
feat: add support for Fedora distribution [SPI-1234]

Implements support for Fedora Linux as a guest distribution.
Users can now specify `os.distro = "fedora"` in their Vagrantfile.

- Added Fedora to supported distributions list
- Updated validation to accept fedora as valid distro
- Added integration test for Fedora machine creation
```

**Bug fix:**
```
fix: correct state detection for stopped machines

Previously, stopped machines were incorrectly reported as :not_created.
This fix ensures proper state mapping from OrbStack CLI output.

Fixes #123
```

**Documentation update:**
```
docs: update installation instructions in README

Added troubleshooting section for common installation issues
and clarified OrbStack CLI requirements.
```

**Breaking change (pre-1.0 only):**
```
feat: rename machine_name to custom_name

BREAKING CHANGE: The `machine_name` configuration attribute has been
renamed to `custom_name` for consistency with Vagrant conventions.

Migration: Update Vagrantfiles from `os.machine_name = "foo"` to
`os.custom_name = "foo"`.
```

### Linear Issue References

For maintainers and team members working with Linear:
- Format: `[SPI-XXX]` at the end of the subject line
- Optional but recommended for tracking
- External contributors: Don't worry about Linear references; maintainers will add them if needed

### Validation

Your commits will be validated by:
- **Pre-commit hooks** (if you install git hooks via `./bin/install-git-hooks`)
- **CI/CD pipeline** (automatic on PR submission)
- **Release-Please** (generates changelog from commit messages)

If your commit message doesn't follow the convention, the CI build will fail, and you'll be asked to reformat.

## Development Setup

### Prerequisites

- **macOS**: 12 (Monterey) or later (OrbStack is macOS-only)
- **Ruby**: 2.6 or higher
- **Bundler**: `gem install bundler`
- **Vagrant**: 2.2.0 or higher
- **OrbStack**: Latest stable version from [orbstack.dev](https://orbstack.dev/)

### Setup Steps

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/vagrant-orbstack-provider.git
   cd vagrant-orbstack-provider
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Install git hooks** (optional but recommended)
   ```bash
   ./bin/install-git-hooks
   ```
   This installs pre-push hooks that run RuboCop and RSpec before pushing code.

4. **Verify setup**
   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```
   You should see all tests passing and zero RuboCop offenses.

For detailed development guidelines, see [DEVELOPMENT.md](./DEVELOPMENT.md).

## Testing

This project follows **Test-Driven Development (TDD)**. All new features must include tests.

### Running Tests

```bash
# Run all unit tests (fast feedback)
bundle exec rspec

# Run specific test file
bundle exec rspec spec/vagrant-orbstack/provider_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation
```

### Test Requirements

**For all code changes:**
- All new features must include tests
- Bug fixes should include regression tests to prevent recurrence
- Maintain or improve code coverage (currently >95%)
- All tests must pass before submitting PR

**For documentation-only changes:**
- Tests are not required for documentation updates (README, docs/, etc.)

### Testing Philosophy

Our tests follow the **testing pyramid**:
- **70% Unit Tests**: Fast, isolated tests with mocked dependencies
- **20% Integration Tests**: Component interaction tests
- **10% End-to-End Tests**: Full workflow validation (requires OrbStack)

When writing tests:
- Test **behavior**, not implementation details
- Mock external dependencies (OrbStack CLI, filesystem)
- Follow AAA pattern (Arrange, Act, Assert)
- Use descriptive test names

For comprehensive testing guidelines, see [docs/TDD.md](./docs/TDD.md).

## Pull Request Process

### Before Submitting

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

   Branch prefixes: `feat/`, `fix/`, `docs/`, `test/`, `refactor/`, `chore/`

2. **Make your changes with conventional commits**
   ```bash
   git commit -m "feat: add support for Alpine Linux"
   ```

3. **Run quality checks**
   ```bash
   # Run tests
   bundle exec rspec

   # Check code style
   bundle exec rubocop

   # Auto-fix style issues (safe fixes only)
   bundle exec rubocop -A

   # Build gem to verify it packages correctly
   gem build vagrant-orbstack.gemspec
   ```

4. **Push to your fork**
   ```bash
   git push origin feat/your-feature-name
   ```

### Pull Request Checklist

Before submitting your PR, ensure:

- [ ] **Conventional commits** used for all commits
- [ ] **Tests added/updated** for code changes (not needed for docs-only)
- [ ] **RuboCop passes** with zero offenses (`bundle exec rubocop`)
- [ ] **All tests pass** (`bundle exec rspec`)
- [ ] **Documentation updated** if you changed behavior or added features
- [ ] **CHANGELOG.md updated** (optional - maintainers will handle via Release-Please)
- [ ] **Linear issue referenced** (optional - for team members only)

### Review Process

1. **Automated checks**: CI runs tests and RuboCop automatically
2. **Code review**: At least one maintainer will review your PR
3. **Approval required**: You'll need approval before merging
4. **Merge strategy**: We use squash or rebase merging (maintainer will handle)

**After merge:**
- Your changes will appear in the next release
- Release-Please will automatically include your commit in the changelog
- You'll be credited in the release notes

## Code Style

We follow the [Ruby Style Guide](https://rubystyle.guide/) and enforce it with RuboCop.

### Key Conventions

- **Indentation**: 2 spaces (no tabs)
- **Line length**: Maximum 120 characters
- **Naming**:
  - `snake_case` for methods and variables
  - `PascalCase` for classes and modules
  - `SCREAMING_SNAKE_CASE` for constants
- **Strings**: Prefer single quotes unless interpolation is needed
- **Frozen string literals**: Use `# frozen_string_literal: true` at the top of files
- **Documentation**: YARD comments for all public methods

### Auto-Fixing Style Issues

RuboCop can automatically fix many style issues:

```bash
# Auto-fix safe offenses
bundle exec rubocop -A

# Check specific file
bundle exec rubocop lib/vagrant-orbstack/provider.rb

# Show only errors (ignore warnings)
bundle exec rubocop --fail-level error
```

### Documentation Standards

All public methods should include YARD documentation:

```ruby
# Creates a new OrbStack machine with specified configuration.
#
# @param [String] name The machine name
# @param [String] distro The Linux distribution (ubuntu, debian, fedora)
# @return [Boolean] true if creation succeeded
# @raise [OrbStackError] if OrbStack CLI fails
#
# @example Create Ubuntu machine
#   create_machine("my-vm", "ubuntu")
#
def create_machine(name, distro)
  # implementation
end
```

## Code of Conduct

### Our Standards

We are committed to providing a welcoming and inclusive environment:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and help them succeed
- **Be constructive**: Provide helpful, actionable feedback
- **Focus on community benefit**: What's best for the project and users

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting, or derogatory remarks
- Personal or political attacks
- Publishing others' private information

### Reporting

If you experience or witness unacceptable behavior, please contact the maintainers:
- Open a confidential issue
- Email: [Contact info in GitHub profile]
- Linear workspace: For team members

## Questions & Resources

### Getting Help

- **Bug reports**: [GitHub Issues](https://github.com/spiralhouse/vagrant-orbstack-provider/issues)
- **Feature requests**: [GitHub Discussions](https://github.com/spiralhouse/vagrant-orbstack-provider/discussions)
- **Documentation**: [README.md](./README.md), [DEVELOPMENT.md](./DEVELOPMENT.md)

### Documentation

- **[README.md](./README.md)**: User guide and quick start
- **[DEVELOPMENT.md](./DEVELOPMENT.md)**: Detailed development workflow
- **[docs/PRD.md](./docs/PRD.md)**: Product requirements
- **[docs/DESIGN.md](./docs/DESIGN.md)**: Technical architecture
- **[docs/TDD.md](./docs/TDD.md)**: Testing philosophy and TDD workflow

### External Resources

- **[Conventional Commits Specification](https://www.conventionalcommits.org/)**: Commit message format
- **[Keep a Changelog](https://keepachangelog.com/)**: Changelog format guidelines
- **[Semantic Versioning](https://semver.org/)**: Version numbering scheme
- **[Vagrant Plugin Development](https://developer.hashicorp.com/vagrant/docs/plugins)**: Vagrant plugin API
- **[OrbStack Documentation](https://docs.orbstack.dev/)**: OrbStack CLI and features
- **[Ruby Style Guide](https://rubystyle.guide/)**: Ruby coding conventions

---

## Thank You!

We appreciate your contributions to vagrant-orbstack-provider. Every contribution, no matter how small, helps make this project better for everyone.

If you have questions or need help, don't hesitate to ask in GitHub Discussions or open an issue. We're here to help!

**Happy coding!**
