# Development Guide

This guide provides detailed information for contributors developing the vagrant-orbstack-provider plugin.

## Table of Contents

- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Local Testing with Vagrant](#local-testing-with-vagrant)
- [Debugging](#debugging)
- [Conventions](#conventions)
- [Architecture Overview](#architecture-overview)

## Development Environment

### Prerequisites

Before you begin development, ensure you have:

- **macOS**: 12 (Monterey) or later (OrbStack is macOS-only)
- **Ruby**: 2.6 or higher (check with `ruby -v`)
- **Bundler**: Latest version (install with `gem install bundler`)
- **Vagrant**: 2.2.0 or higher (install from [vagrantup.com](https://www.vagrantup.com/))
- **OrbStack**: Latest stable version (install from [orbstack.dev](https://orbstack.dev/))
- **Git**: For version control

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/johnburbridge/vagrant-orbstack-provider.git
cd vagrant-orbstack-provider

# Install dependencies
bundle install

# Verify setup
bundle exec rspec
bundle exec rubocop
```

You should see all tests passing and no RuboCop offenses.

## Project Structure

```
vagrant-orbstack-provider/
├── lib/
│   ├── vagrant-orbstack.rb              # Main entry point (loads plugin)
│   └── vagrant-orbstack/
│       ├── plugin.rb                    # Plugin registration with Vagrant
│       ├── version.rb                   # VERSION constant
│       ├── provider.rb                  # Provider class (Vagrant interface)
│       ├── config.rb                    # Configuration class
│       └── action/                      # Action middleware (future)
│           ├── create.rb
│           ├── destroy.rb
│           ├── halt.rb
│           └── ssh_info.rb
├── spec/
│   ├── spec_helper.rb                   # RSpec configuration
│   └── vagrant-orbstack/
│       ├── plugin_spec.rb               # Plugin registration tests
│       ├── version_spec.rb              # Version constant tests
│       ├── provider_spec.rb             # Provider interface tests
│       └── config_spec.rb               # Configuration tests
├── docs/
│   ├── PRD.md                          # Product requirements document
│   ├── DESIGN.md                       # Technical design document
│   ├── TDD.md                          # Test-driven development workflow
│   └── epic-dependency-graph.md        # Feature dependency graph
├── .claude/                            # Claude Code agent artifacts
│   ├── handoffs/                       # Session handoff documents
│   └── baseline/                       # Quality baseline tracking
├── Gemfile                             # Ruby dependencies
├── vagrant-orbstack.gemspec            # Gem specification
├── .rubocop.yml                        # RuboCop configuration
├── .rspec                              # RSpec configuration
├── README.md                           # User-facing documentation
├── DEVELOPMENT.md                      # This file
├── CHANGELOG.md                        # Version history
├── CLAUDE.md                           # Agent workflow and conventions
└── LICENSE                             # MIT license
```

### Key Components

**`lib/vagrant-orbstack/plugin.rb`**
- Registers the plugin with Vagrant
- Defines plugin name, description, and components
- Registers provider and configuration classes

**`lib/vagrant-orbstack/config.rb`**
- Configuration class for Vagrantfile options
- Defines `distro`, `version`, `machine_name` attributes
- Implements validation and finalization

**`lib/vagrant-orbstack/provider.rb`**
- Provider class implementing Vagrant's provider interface
- Defines action hooks for lifecycle operations
- Currently contains stubs for future implementation

**`lib/vagrant-orbstack/version.rb`**
- Single source of truth for version number
- Used by gemspec and plugin registration

## Development Workflow

This project follows **Test-Driven Development (TDD)** with a strict **RED-GREEN-REFACTOR** cycle.

### Standard Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feat/your-feature
   ```

2. **RED Phase: Write Failing Tests**
   - Write tests that describe the desired behavior
   - Ensure tests fail (RED)
   - Example: `spec/vagrant-orbstack/new_feature_spec.rb`

3. **GREEN Phase: Implement Feature**
   - Write minimal code to make tests pass
   - Focus on functionality, not perfection
   - Ensure all tests pass (GREEN)

4. **REFACTOR Phase: Improve Code**
   - Refactor implementation for clarity and maintainability
   - Ensure tests still pass after refactoring
   - Follow Ruby best practices

5. **Verify Quality**
   ```bash
   # Run tests
   bundle exec rspec

   # Check code style
   bundle exec rubocop
   ```

6. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature [SPI-XXX]"
   ```

7. **Create Pull Request**
   - Push branch to GitHub
   - Create PR with description and Linear issue reference
   - Wait for review and approval

### Branch Naming Conventions

- `feat/brief-description` - New features (e.g., `feat/ssh-integration`)
- `fix/brief-description` - Bug fixes (e.g., `fix/state-caching`)
- `docs/brief-description` - Documentation (e.g., `docs/installation-guide`)
- `test/brief-description` - Test additions (e.g., `test/lifecycle-integration`)
- `refactor/brief-description` - Code refactoring (e.g., `refactor/cli-wrapper`)
- `chore/brief-description` - Maintenance tasks (e.g., `chore/rubocop-setup`)

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description> [SPI-XXX]

<optional body>

<optional footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

**Examples:**
```bash
git commit -m "feat: add SSH connection info retrieval [SPI-1142]"
git commit -m "fix: correct state detection for stopped machines [SPI-1145]"
git commit -m "docs: update configuration reference [SPI-1130]"
git commit -m "test: add integration tests for machine lifecycle [SPI-1144]"
```

## Testing

### Running Tests

```bash
# Run all unit tests (excludes integration tests)
bundle exec rake spec
# or simply:
bundle exec rake

# Run integration tests only
bundle exec rake spec:integration

# Run all tests (unit + integration)
bundle exec rake spec:all

# Alternative: Direct RSpec commands
bundle exec rspec                                     # All tests
bundle exec rspec spec/vagrant-orbstack/plugin_spec.rb  # Specific file
bundle exec rspec spec/vagrant-orbstack/plugin_spec.rb:42  # Specific test
bundle exec rspec --format documentation              # Verbose output
bundle exec rspec --backtrace                         # With backtrace
```

### Test Structure

Tests are organized by component:

```
spec/
├── spec_helper.rb              # RSpec configuration and helpers
└── vagrant-orbstack/
    ├── plugin_spec.rb          # Plugin registration tests
    ├── version_spec.rb         # Version constant tests
    ├── provider_spec.rb        # Provider interface tests
    └── config_spec.rb          # Configuration tests
```

### Writing Tests

Follow these guidelines when writing tests:

1. **Describe behavior, not implementation**
   ```ruby
   # Good
   it 'returns the machine name when set' do
     # ...
   end

   # Bad
   it 'returns @machine_name instance variable' do
     # ...
   end
   ```

2. **Use descriptive test names**
   - Start with action verbs (returns, raises, sets, validates)
   - Be specific about expected behavior
   - Include context when relevant

3. **Follow AAA pattern** (Arrange, Act, Assert)
   ```ruby
   it 'validates distribution name' do
     # Arrange
     config.distro = 'invalid-distro'

     # Act
     errors = config.validate(machine)

     # Assert
     expect(errors['OrbStack Provider']).to include('Invalid distribution')
   end
   ```

4. **Mock external dependencies**
   ```ruby
   let(:machine) { double('machine') }
   let(:provider) { double('provider') }
   ```

5. **Test edge cases and error conditions**
   - Invalid inputs
   - Nil values
   - Empty strings
   - State transitions

### Testing Philosophy

- **70% unit tests**: Test individual components in isolation
- **20% integration tests**: Test component interactions
- **10% end-to-end tests**: Test complete workflows

Focus on **critical paths** and **error handling**.

## Code Quality

### RuboCop (Linting)

RuboCop enforces Ruby style guidelines and detects common issues.

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -A

# Show only errors (not warnings)
bundle exec rubocop --fail-level error

# Check specific file
bundle exec rubocop lib/vagrant-orbstack/provider.rb
```

**Configuration**: `.rubocop.yml` defines project-specific rules.

### YARD Documentation

All public methods and classes should have YARD documentation.

```ruby
# @example Creating a new machine
#   config.vm.provider :orbstack do |os|
#     os.distro = "ubuntu"
#     os.version = "22.04"
#   end
#
# @param [String] distro Distribution name
# @return [void]
def some_method(distro)
  # implementation
end
```

Generate documentation:

```bash
# Generate YARD docs
yard doc

# View documentation
open doc/index.html
```

### Code Style Guidelines

- **Indentation**: 2 spaces (no tabs)
- **Line length**: Max 120 characters
- **String literals**: Prefer single quotes unless interpolation needed
- **Method length**: Keep methods short and focused (<10 lines ideal)
- **Class length**: Keep classes focused on single responsibility
- **Comments**: Write self-documenting code; use comments for "why", not "what"

### Build Automation (Rakefile)

The project includes a Rakefile with common development tasks:

```bash
# List all available tasks
bundle exec rake -T

# Run tests (default task)
bundle exec rake           # Runs unit tests
bundle exec rake spec      # Runs unit tests (explicit)

# Test variants
bundle exec rake spec:integration  # Integration tests only
bundle exec rake spec:e2e          # E2E tests only (requires OrbStack)
bundle exec rake spec:all          # All tests (unit + integration + e2e)

# Build and package
bundle exec rake build     # Build gem to pkg/ directory
bundle exec rake install   # Build and install gem locally
bundle exec rake clean     # Remove build artifacts

# Release (future use)
bundle exec rake release   # Build, tag, and push to RubyGems
```

**Task Descriptions:**
- **spec**: Runs unit tests (excludes integration and e2e tests for fast feedback)
- **spec:integration**: Runs integration tests for Rakefile tasks
- **spec:e2e**: Runs end-to-end tests (requires OrbStack and Vagrant installed)
- **spec:all**: Runs complete test suite (unit + integration + e2e)
- **build**: Creates `.gem` file in `pkg/` directory
- **install**: Builds and installs gem to local gem repository
- **clean**: Removes `pkg/` directory and build artifacts
- **release**: Tags version and publishes to RubyGems (requires credentials)

## Local Testing with Vagrant

### Building and Installing the Gem

```bash
# Build gem using Rake
bundle exec rake build

# Alternative: Direct gem build command
gem build vagrant-orbstack.gemspec

# Install plugin to Vagrant
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem

# Verify installation
vagrant plugin list

# Clean build artifacts
bundle exec rake clean
```

### Updating After Code Changes

```bash
# Uninstall old version
vagrant plugin uninstall vagrant-orbstack

# Rebuild and reinstall using Rake
bundle exec rake build
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem

# Alternative: One-step install (builds if needed)
bundle exec rake install
```

### Testing with Vagrantfile

Create a test directory:

```bash
mkdir -p ~/vagrant-test/orbstack-test
cd ~/vagrant-test/orbstack-test
```

Create `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
    os.machine_name = "test-machine"
  end
end
```

Test commands:

```bash
# Create machine
vagrant up --provider=orbstack

# Check status
vagrant status

# SSH (when implemented)
vagrant ssh

# Stop machine
vagrant halt

# Destroy machine
vagrant destroy
```

### Debugging Vagrant Commands

Enable debug logging:

```bash
# Maximum verbosity
VAGRANT_LOG=debug vagrant up --provider=orbstack

# Log to file
VAGRANT_LOG=debug vagrant up --provider=orbstack 2>&1 | tee vagrant.log
```

## Debugging

### Using Pry for Debugging

Add `pry` to development dependencies (already included in Gemfile):

```ruby
require 'pry'

def some_method
  # Add breakpoint
  binding.pry

  # Code here will pause execution
end
```

Run tests with pry:

```bash
bundle exec rspec
```

When execution hits `binding.pry`, you'll get an interactive console.

### Debugging Tips

1. **Use `@logger` in provider classes**
   ```ruby
   @logger.debug("Current machine state: #{state}")
   @logger.info("Creating machine with distro: #{@config.distro}")
   ```

2. **Check Vagrant logs**
   ```bash
   # View Vagrant debug output
   VAGRANT_LOG=debug vagrant up --provider=orbstack
   ```

3. **Inspect test failures**
   ```bash
   # Run with backtrace
   bundle exec rspec --backtrace

   # Run specific failing test
   bundle exec rspec spec/vagrant-orbstack/provider_spec.rb:42
   ```

4. **Use RSpec's `focus` flag for targeted testing**
   ```ruby
   it 'some test', :focus do
     # This test will run exclusively
   end
   ```

   Then run: `bundle exec rspec --tag focus`

## Conventions

### Ruby Style

Follow the [Ruby Style Guide](https://rubystyle.guide/):

- Use `snake_case` for methods and variables
- Use `PascalCase` for classes and modules
- Use `SCREAMING_SNAKE_CASE` for constants
- Prefer explicit over implicit
- Use meaningful variable names

### File Naming

- Ruby files: `snake_case.rb`
- Spec files: `*_spec.rb` (matches source file name)
- Class per file (Ruby convention)

### Testing Conventions

- Use `let` for test data setup
- Use `subject` for the object under test
- Use `describe` for grouping related tests
- Use `context` for different scenarios
- Use `it` for individual test cases

### Documentation Conventions

- Write YARD docs for all public methods
- Include `@example` blocks for complex usage
- Document parameters with `@param`
- Document return values with `@return`
- Mark internal APIs with `@api private`

### Git Conventions

- **Never commit directly to `main`**
- Create short-lived feature branches
- Merge branches quickly (within 1-2 days)
- Delete branches after merging
- Keep commits atomic and focused
- Write descriptive commit messages

## Architecture Overview

### Vagrant Plugin Architecture

Vagrant uses a plugin architecture with these key components:

1. **Plugin**: Registers components with Vagrant
2. **Provider**: Implements machine lifecycle operations
3. **Config**: Defines configuration options for Vagrantfile
4. **Action**: Middleware for executing operations (future)

### OrbStack Integration

The provider integrates with OrbStack via CLI:

```
Vagrant → Provider → OrbStack CLI → OrbStack
```

**Design Decisions:**
- Shell out to `orb` CLI rather than direct API integration
- Cache state queries (5-second TTL) to reduce latency
- Auto-generate machine names as `vagrant-<name>-<id>`
- Document OrbStack's native file sharing (no custom mounting)

For complete architecture details, see [`docs/DESIGN.md`](./docs/DESIGN.md).

### Test-Driven Development Process

This project uses a structured TDD workflow with agent delegation:

1. **Planning**: Engineering manager analyzes requirements
2. **RED Phase**: Test engineer writes failing tests
3. **GREEN Phase**: Ruby developer implements features
4. **REFACTOR Phase**: Software architect analyzes → Ruby developer refactors
5. **Review**: Code reviewer ensures quality

For complete TDD workflow, see [`docs/TDD.md`](./docs/TDD.md).

## Resources

### Documentation

- [README.md](./README.md) - User-facing documentation
- [docs/PRD.md](./docs/PRD.md) - Product requirements
- [docs/DESIGN.md](./docs/DESIGN.md) - Technical design
- [docs/TDD.md](./docs/TDD.md) - TDD workflow
- [CLAUDE.md](./CLAUDE.md) - Agent workflow and conventions

### Vagrant Resources

- [Vagrant Documentation](https://developer.hashicorp.com/vagrant)
- [Vagrant Provider Plugin Development](https://developer.hashicorp.com/vagrant/docs/plugins/providers)
- [Vagrant Plugin Development Guide](https://developer.hashicorp.com/vagrant/docs/plugins)

### OrbStack Resources

- [OrbStack Official Website](https://orbstack.dev/)
- [OrbStack Documentation](https://docs.orbstack.dev/)
- [OrbStack Linux Machines](https://docs.orbstack.dev/machines/)
- [OrbStack CLI Reference](https://docs.orbstack.dev/machines/commands)

### Ruby Resources

- [Ruby Style Guide](https://rubystyle.guide/)
- [RSpec Documentation](https://rspec.info/)
- [RuboCop Documentation](https://docs.rubocop.org/)
- [YARD Documentation](https://yardoc.org/)

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/johnburbridge/vagrant-orbstack-provider/issues)
- **Discussions**: [GitHub Discussions](https://github.com/johnburbridge/vagrant-orbstack-provider/discussions)
- **Linear**: Internal project tracking

---

**Happy coding!** Remember to write tests first and keep the RED-GREEN-REFACTOR cycle going.
