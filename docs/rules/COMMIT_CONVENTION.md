# Commit Message Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

Must be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Scope (optional)

The scope should be the name of the npm package or module affected (e.g., `visit`, `travel`, `dashboard`, `auth`).

### Subject

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize first letter
- No period (.) at the end
- Maximum 100 characters

### Body (optional)

- Use imperative, present tense
- Include motivation for the change and contrasts with previous behavior

### Footer (optional)

- Reference GitHub issues or breaking changes
- Breaking changes should start with `BREAKING CHANGE:` followed by a description

## Examples

### Feature
```
feat(visit): add export to Excel functionality

Implement export feature for visit list with filters applied.
Supports CSV and XLSX formats.

Closes #123
```

### Bug Fix
```
fix(travel): correct date validation in travel form

The date picker was allowing past dates which caused server errors.
Now validates that travel dates are in the future.
```

### Breaking Change
```
feat(api)!: change authentication endpoint structure

BREAKING CHANGE: Authentication endpoint now requires API version in header.
Update all API calls to include `X-API-Version: 2.0` header.
```

### Simple Commit
```
docs: update README with devcontainer instructions
```

## Commitlint

Commits are automatically validated using commitlint. Invalid commit messages will be rejected.

To test your commit message:
```bash
echo "feat: add new feature" | npx commitlint
```

## Husky Hooks

This project uses Husky for Git hooks:

- **commit-msg**: Validates commit messages against conventional commits format
- **pre-commit**: Runs linting checks on staged files (optional)

To bypass hooks (not recommended):
```bash
git commit --no-verify -m "your message"
```
