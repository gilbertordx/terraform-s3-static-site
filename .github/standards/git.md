# Git & Version Control Standards

## Commit Messages
**Format:** Conventional Commits
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or correcting tests
- `chore`: Maintenance (dependencies, build scripts)
- `ci`: CI/CD pipeline changes
- `security`: Security fixes or improvements

**Examples:**
```
feat(auth): add JWT token refresh mechanism
fix(s3): correct bucket policy for public read access
docs(readme): add setup instructions for local development
security(api): implement rate limiting on login endpoint
```

**Rules:**
- Use present tense ("add feature" not "added feature")
- Capitalize first letter of description
- No period at end of description
- Body explains **what** and **why**, not **how**
- Reference issues/tickets in footer: `Fixes #123`

## Branch Naming
**Pattern:** `<type>/<short-description>`

**Examples:**
```
feat/user-authentication
fix/s3-bucket-permissions
refactor/terraform-module-structure
docs/api-documentation
```

**Rules:**
- Use lowercase and hyphens
- Keep names short but descriptive (3-5 words max)
- No issue numbers in branch name (use commit message footer)

## Branch Strategy
- `main`: Production-ready code only
- `develop`: Integration branch for features (if using Gitflow)
- Feature branches: Created from `main` or `develop`
- Hotfix branches: Created from `main` for critical production fixes

## Pull Request Requirements
**Before PR:**
- All tests pass locally
- Code is formatted (`terraform fmt`, `go fmt`, etc.)
- No linter warnings
- Commits are atomic and well-described

**PR Description Must Include:**
- Summary of changes
- Motivation and context
- Testing performed
- Screenshots (if UI changes)
- Checklist of completed items

**Merge Requirements:**
- At least 1 approval (2 for critical changes)
- All CI checks pass
- No merge conflicts
- Branch is up to date with target

## Protected Branches
- `main` requires PR approval
- No force push to `main`
- Delete feature branches after merge

## Commit Hygiene
- Make atomic commits (one logical change per commit)
- Commit early and often locally
- Squash/rebase before PR if commits are messy
- Never commit secrets, credentials, or `.env` files
- Use `.gitignore` properly
