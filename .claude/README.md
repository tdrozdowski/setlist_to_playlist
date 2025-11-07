# .claude/ Documentation

This directory contains detailed documentation for the Setlist Playlist Builder project.

## File Overview

| File | Lines | Purpose |
|------|-------|---------|
| **[BUILD.md](BUILD.md)** | ~680 | Makefile targets, build system, development workflow |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | ~450 | Layered architecture, design patterns, module structure |
| **[DEPENDENCIES.md](DEPENDENCIES.md)** | ~430 | Dependency management, version policy, core crates |
| **[TESTING.md](TESTING.md)** | ~640 | Testing philosophy, coverage requirements, mocking |
| **[CICD.md](CICD.md)** | ~570 | GitHub Actions workflows, release process, branch protection |

## Quick Navigation

### For Build Questions
→ [BUILD.md](BUILD.md)
- Makefile targets (build, test, coverage, ci-check, etc.)
- Development workflow (first-time setup, daily development)
- Troubleshooting build issues
- Rust + Swift build process

### For Architecture Questions
→ [ARCHITECTURE.md](ARCHITECTURE.md)
- Layer responsibilities (CLI, Controllers, Services, Adapters, Clients, Domain)
- Dependency flow and rules
- Module structure (Rust 2018+, no mod.rs files)
- FFI bridge design patterns

### For Dependency Questions
→ [DEPENDENCIES.md](DEPENDENCIES.md)
- Adding new dependencies (always use latest stable)
- Core pillars: tokio, reqwest, swift-bridge
- Evaluation criteria for new crates
- Keeping dependencies updated

### For Testing Questions
→ [TESTING.md](TESTING.md)
- 80% minimum coverage requirement
- What to test (services, algorithms, domain) vs what to skip (trivial code)
- Using mockall for trait mocking
- Unit tests vs integration tests

### For CI/CD Questions
→ [CICD.md](CICD.md)
- Pull request checks (format, clippy, tests, coverage)
- Release workflow (auto-release on merge to main)
- Branch protection rules
- Troubleshooting CI failures

## Usage for AI Agents

When working on this project, Claude Code can:

1. **Parse CLAUDE.md first** - Get quick overview and essential commands
2. **Reference specific docs** - Dive deep into architecture, testing, etc. as needed
3. **Follow patterns** - Use examples in detailed docs as templates

Example workflow:
```
User: "Add a new service for song matching"
Agent: 
  1. Read CLAUDE.md (quick context)
  2. Read ARCHITECTURE.md (understand service layer)
  3. Read TESTING.md (understand testing requirements)
  4. Implement service with 90%+ coverage
  5. Follow module structure (no mod.rs)
```

## Documentation Maintenance

Keep docs updated when:
- ✅ Architecture changes (new layers, patterns)
- ✅ Dependency policy changes
- ✅ Testing requirements change
- ✅ CI/CD workflows change
- ✅ New common gotchas discovered

Don't update for:
- ❌ Minor code changes
- ❌ Bug fixes
- ❌ Specific implementation details
