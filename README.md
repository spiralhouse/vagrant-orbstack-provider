# vagrant-orbstack-provider

A Vagrant provider plugin that enables [OrbStack](https://orbstack.dev/) as a backend for managing Linux development environments on macOS.

![Development Status](https://img.shields.io/badge/status-alpha-orange)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
[![codecov](https://codecov.io/gh/spiralhouse/vagrant-orbstack-provider/graph/badge.svg?token=VIHOdRkRJ9)](https://codecov.io/gh/spiralhouse/vagrant-orbstack-provider)
![License](https://img.shields.io/badge/license-MIT-green)

## Project Overview

OrbStack is a high-performance alternative to traditional VM solutions on macOS, offering:
- Sub-3-second startup times
- Near-zero idle resource consumption
- Native macOS integration with excellent file sharing
- First-class support for Apple Silicon and Intel Macs

This provider allows you to leverage OrbStack's performance while maintaining the familiar Vagrant workflow.

> **Development Status**: This provider is under active development. Most features are not yet implemented. See [Project Status](#project-status) for details.

## Requirements

### System Requirements
- **Operating System**: macOS 12 (Monterey) or later
- **Architecture**: Apple Silicon (ARM64) or Intel (x86_64)
- **Vagrant**: Version 2.2.0 or higher
- **Ruby**: Version 2.6 or higher
- **OrbStack**: Latest stable version with CLI tools installed

### Installation

OrbStack must be installed and running on your system:
1. Download and install [OrbStack](https://orbstack.dev/)
2. Verify OrbStack CLI is available: `orb version`

## Installation

Since the plugin is not yet published to RubyGems, you'll need to build and install it locally:

```bash
# Clone the repository
git clone https://github.com/johnburbridge/vagrant-orbstack-provider.git
cd vagrant-orbstack-provider

# Install dependencies
bundle install

# Build the gem
gem build vagrant-orbstack.gemspec

# Install the plugin locally
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem
```

Verify the installation:

```bash
vagrant plugin list
```

You should see `vagrant-orbstack (0.1.0)` in the output.

## Quick Start

Create a `Vagrantfile` in your project directory:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"

  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
  end
end
```

Basic commands:

```bash
# Create and start the machine
vagrant up --provider=orbstack

# Check machine status
vagrant status

# SSH into the machine
vagrant ssh

# Stop the machine
vagrant halt

# Destroy the machine
vagrant destroy
```

## Usage

### Creating a Machine

Create and start an OrbStack machine with Vagrant:

```bash
vagrant up --provider=orbstack
```

This will:
- Create a new OrbStack machine with automatic naming
- Start the machine immediately
- Be idempotent (safe to run multiple times—existing machines are not recreated)

### Machine Naming

Machines are automatically named using the convention:
- Format: `vagrant-<machine-name>-<short-id>`
- Example: `vagrant-default-a3b2c1`
- The short ID ensures uniqueness for multi-machine setups

The machine name can be customized in your Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :orbstack do |os|
    os.machine_name = "my-dev-env"
  end
end
```

With this configuration, your machine will be named `vagrant-my-dev-env-<short-id>`.

### Halt and Resume

Stop a running machine:

```bash
vagrant halt
```

Resume a halted machine:

```bash
vagrant up  # Resumes existing machine
```

Check machine status:

```bash
vagrant status
```

### Multi-Machine Support

Define multiple machines in your Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.provider "orbstack" do |orbstack|
      orbstack.distro = "ubuntu"
      orbstack.version = "noble"
    end
  end

  config.vm.define "db" do |db|
    db.vm.provider "orbstack" do |orbstack|
      orbstack.distro = "debian"
    end
  end
end
```

Each machine gets a unique name (e.g., `vagrant-web-a3b2c1`, `vagrant-db-d4e5f6`). You can manage them individually:

```bash
# Create web machine
vagrant up web --provider=orbstack

# Create db machine
vagrant up db --provider=orbstack

# Check status of all machines
vagrant status

# SSH into web machine
vagrant ssh web

# Halt specific machine
vagrant halt web
```

## Configuration

The OrbStack provider supports several configuration options to customize your development environment. All configuration is optional—the provider uses sensible defaults following Vagrant's convention-over-configuration philosophy.

### Basic Configuration

The minimal Vagrantfile requires no provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    # Uses defaults: Ubuntu distribution
  end
end
```

### Configuration Options

| Option | Type | Default | Required | Description |
|--------|------|---------|----------|-------------|
| `distro` | String | `"ubuntu"` | No | Linux distribution to use |
| `version` | String | `nil` | No | Distribution version (e.g., "22.04") |
| `machine_name` | String | `nil` (auto-generated) | No | Custom OrbStack machine name |

#### Validation Rules

- **distro**: Cannot be empty or blank. The provider validates this at runtime.
- **machine_name**: If specified, must contain only alphanumeric characters (a-z, A-Z, 0-9) and hyphens (-). Must start and end with an alphanumeric character. No consecutive hyphens allowed.
  - Valid examples: `"my-dev-env"`, `"project-1"`, `"ubuntu-machine"`
  - Invalid examples: `"-invalid"`, `"invalid-"`, `"invalid--name"`, `"invalid_name"`

### Configuration Examples

#### Default Configuration

The simplest configuration uses all defaults:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    # All options use defaults
    # distro: "ubuntu"
    # version: nil
    # machine_name: nil (auto-generated)
  end
end
```

#### Specify Distribution and Version

Choose a specific Linux distribution and version:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
  end
end
```

#### Custom Machine Name

Provide a custom name for your OrbStack machine:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.machine_name = "my-dev-machine"
  end
end
```

#### Complete Configuration

Specify all available options:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
    os.machine_name = "my-dev-environment"
  end
end
```

#### Different Distributions

Examples using various Linux distributions:

```ruby
# Debian
Vagrant.configure("2") do |config|
  config.vm.box = "debian"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "debian"
    os.version = "12"
    os.machine_name = "debian-dev"
  end
end

# Fedora
Vagrant.configure("2") do |config|
  config.vm.box = "fedora"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "fedora"
    os.version = "39"
    os.machine_name = "fedora-dev"
  end
end

# Alpine Linux
Vagrant.configure("2") do |config|
  config.vm.box = "alpine"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "alpine"
    os.version = "3.19"
    os.machine_name = "alpine-dev"
  end
end
```

### Supported Distributions

The provider supports the following Linux distributions available in OrbStack:

- **Ubuntu** (default) - Popular Debian-based distribution
- **Debian** - Stable, universal Linux distribution
- **Fedora** - Cutting-edge features and latest packages
- **Arch Linux** - Rolling release, minimalist distribution
- **Alpine Linux** - Lightweight, security-oriented distribution

**Note**: Distribution availability depends on your OrbStack installation. Refer to the [OrbStack documentation](https://docs.orbstack.dev/machines/) for the most current list of supported distributions and versions.

## Project Status

### Implemented

- **Foundation (v0.1.0)**:
  - Plugin registration and gem structure (SPI-1130)
  - Configuration class with `distro`, `version`, `machine_name` attributes
  - Provider interface foundation
  - Test infrastructure (RSpec)
  - YARD documentation for public APIs
  - RuboCop clean (0 offenses)

- **State Management (v0.2.0-dev)**:
  - Machine state query implementation (SPI-1199)
  - Provider#state method returns accurate Vagrant::MachineState
  - StateCache utility with 5-second TTL for performance optimization
  - State mapping: OrbStack states (running, stopped) → Vagrant states (:running, :stopped, :not_created)
  - Cache invalidation support (per-key and global)
  - Graceful error handling for CLI failures and timeouts

- **Machine Creation and Naming (v0.2.0-dev)**:
  - Machine creation via `vagrant up --provider=orbstack` (SPI-1200)
  - Automatic machine naming with format `vagrant-<name>-<short-id>`
  - Idempotent operations (safe to run multiple times)
  - Multi-machine support with unique name generation
  - State-aware creation (checks if machine exists before creating)
  - MachineNamer utility for unique name generation
  - Create action middleware implementation

- **Machine Lifecycle Management (v0.2.0-dev)**:
  - Machine halt via `vagrant halt` (SPI-1201)
  - Machine resume via `vagrant up` on stopped machines (SPI-1201)
  - Halt and Start action middleware implementations
  - State cache invalidation for accurate status queries
  - Idempotent halt/start operations (safe to run multiple times)
  - User-friendly progress messages with machine IDs

- **OrbStack CLI Integration (partial)**:
  - CLI wrapper with command execution and timeout support
  - Machine listing and info retrieval (SPI-1198)
  - Machine creation and lifecycle methods (SPI-1200)
  - Error handling (CommandTimeoutError, CommandExecutionError, MachineNameCollisionError)
  - Logging infrastructure throughout provider components

- **Test Coverage**:
  - 363 passing tests with comprehensive coverage
  - 99.5% test pass rate
  - 100% coverage of implemented features

### Planned (MVP - v0.2.0+)

- SSH integration for remote access
- Machine destroy operations
- OrbStack CLI wrapper completion (delete command)
- Provisioner support (Shell, Ansible, Chef, Puppet)
- Synced folder configuration
- Error handling and recovery mechanisms
- Additional Linux distribution support

For complete roadmap, see [`docs/PRD.md`](./docs/PRD.md).

## Development

### Setup

```bash
# Clone and setup
git clone https://github.com/johnburbridge/vagrant-orbstack-provider.git
cd vagrant-orbstack-provider
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/vagrant-orbstack/provider_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Code Quality

```bash
# Run RuboCop (linter)
bundle exec rubocop

# Auto-fix offenses
bundle exec rubocop -A

# Generate YARD documentation
yard doc
```

### Local Testing

```bash
# Build and install gem locally
gem build vagrant-orbstack.gemspec
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem

# Create test environment
mkdir test-env && cd test-env
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
  end
end
EOF

# Test (note: most features are stubs currently)
vagrant up --provider=orbstack
```

## Documentation

- **[Product Requirements (PRD)](./docs/PRD.md)**: Complete feature requirements and roadmap
- **[Technical Design (DESIGN)](./docs/DESIGN.md)**: Architecture and implementation details
- **[TDD Workflow (TDD)](./docs/TDD.md)**: Test-driven development process
- **[Development Guide (DEVELOPMENT)](./DEVELOPMENT.md)**: Contributor documentation

## Contributing

This project follows Test-Driven Development (TDD). See [`CLAUDE.md`](./CLAUDE.md) for our development workflow and [`docs/TDD.md`](./docs/TDD.md) for TDD guidelines.

### Development Workflow

1. Create feature branch: `git checkout -b feat/your-feature`
2. Write tests first (RED phase)
3. Implement feature (GREEN phase)
4. Refactor (REFACTOR phase)
5. Ensure tests pass: `bundle exec rspec`
6. Ensure RuboCop passes: `bundle exec rubocop`
7. Commit with conventional commits: `git commit -m "feat: add feature [SPI-XXX]"`
8. Create pull request

### Conventions

- Follow Ruby community style guide
- Use 2-space indentation
- Write YARD documentation for public methods
- Follow conventional commits format (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`)
- Reference Linear issues in commits: `[SPI-XXX]`

## Support

- **Issues**: [GitHub Issues](https://github.com/johnburbridge/vagrant-orbstack-provider/issues)
- **Discussions**: [GitHub Discussions](https://github.com/johnburbridge/vagrant-orbstack-provider/discussions)

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Acknowledgments

- [Vagrant](https://www.vagrantup.com/) - Development environment management
- [OrbStack](https://orbstack.dev/) - High-performance macOS virtualization
- Vagrant provider implementations for architectural guidance

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and release notes.

---

**Made with ❤️ by the Vagrant OrbStack Provider community**
