# Standards Priority Matrix

## CRITICAL (P0): PIPELINE BLOCKERS
**These MUST pass. No exceptions. No deploy without these.**

| Standard | Enforcement | Impact | Reference |
|----------|-------------|--------|-----------|
| **No Secrets in Git** | Pre-commit + CI | 🔴 CRITICAL | `security-standards.md` |
| **80% Test Coverage** | CI | 🔴 CRITICAL | `testing-standards.md` |
| **All Tests Pass** | Pre-commit + CI | 🔴 CRITICAL | `testing-standards.md` |
| **Terraform Validate** | Pre-commit + CI | 🔴 CRITICAL | `copilot-instructions.md` |
| **tfsec Security Scan** | CI | 🔴 CRITICAL | `security-standards.md` |
| **Zero Dependency Vulnerabilities** | CI | 🔴 CRITICAL | `security-standards.md` |

---

## HIGH (P1): QUALITY GATES
**Required for PR merge. Can be fixed quickly.**

| Standard | Enforcement | Impact | Reference |
|----------|-------------|--------|-----------|
| **Code Formatting** | Pre-commit + CI | 🟠 HIGH | `code-style.md` |
| **Linting (no warnings)** | Pre-commit + CI | 🟠 HIGH | `code-style.md` |
| **Conventional Commits** | Pre-commit | 🟠 HIGH | `git-standards.md` |
| **PR Approval (1+ reviewer)** | GitHub | 🟠 HIGH | `git-standards.md` |
| **Encryption Enabled** | Terraform | 🟠 HIGH | `security-standards.md` |
| **IAM Least Privilege** | tfsec/Checkov | 🟠 HIGH | `security-standards.md` |

---

## MEDIUM (P2): BEST PRACTICES
**Should be done. Reviewed in PRs. Not automatic blockers.**

| Standard | Enforcement | Impact | Reference |
|----------|-------------|--------|-----------|
| **README.md Updated** | PR Review | 🟡 MEDIUM | `documentation-standards.md` |
| **Function Documentation** | PR Review | 🟡 MEDIUM | `documentation-standards.md` |
| **ADR for Architecture** | PR Review | 🟡 MEDIUM | `documentation-standards.md` |
| **Branch Naming** | Manual | 🟡 MEDIUM | `git-standards.md` |
| **Rate Limiting Configured** | PR Review | 🟡 MEDIUM | `security-standards.md` |
| **Logging Configured** | PR Review | 🟡 MEDIUM | `security-standards.md` |

---

## LOW (P3): CONTINUOUS IMPROVEMENT
**Nice to have. Improve over time.**

| Standard | Enforcement | Impact | Reference |
|----------|-------------|--------|-----------|
| **Inline Comments (why)** | PR Review | 🟢 LOW | `documentation-standards.md` |
| **Performance Benchmarks** | Manual | 🟢 LOW | `testing-standards.md` |
| **Load Testing** | Manual | 🟢 LOW | `testing-standards.md` |
| **Metrics Dashboard** | Manual | 🟢 LOW | `ci-cd-pipeline.md` |

---

## Quick Reference: What Blocks What

### Pre-Commit Hooks (Local)
```
❌ BLOCKS: Code formatting issues
❌ BLOCKS: Detected secrets
❌ BLOCKS: Invalid commit message format
❌ BLOCKS: Short tests failing
```

### CI Pipeline
```
❌ BLOCKS: Test coverage < 80%
❌ BLOCKS: Any test failure
❌ BLOCKS: Security vulnerabilities (dependencies, container)
❌ BLOCKS: tfsec/Checkov failures
❌ BLOCKS: Linting warnings
❌ BLOCKS: Build failures
```

### PR Merge
```
❌ BLOCKS: Missing PR approval
❌ BLOCKS: Unresolved conversations
❌ BLOCKS: Branch not up-to-date
❌ BLOCKS: Any failed CI check
```

### Deployment
```
❌ BLOCKS: All above + not merged to main
❌ BLOCKS: Failed health check post-deploy
```

---

## Decision Tree: Can I Deploy?

```
START
  │
  ├─> Secrets in git? ──YES──> ❌ BLOCKED
  │                     NO
  │                      │
  ├─> Tests pass? ──NO───> ❌ BLOCKED
  │                YES
  │                 │
  ├─> Coverage ≥80%? ──NO──> ❌ BLOCKED
  │                   YES
  │                    │
  ├─> Terraform valid? ──NO──> ❌ BLOCKED
  │                     YES
  │                      │
  ├─> Security scans pass? ──NO──> ❌ BLOCKED
  │                         YES
  │                          │
  ├─> Code formatted? ──NO───> ❌ BLOCKED
  │                     YES
  │                      │
  ├─> PR approved? ──NO──> ❌ BLOCKED
  │                 YES
  │                  │
  └─> ✅ DEPLOY
```

---

## Implementation Roadmap

### Week 1: Foundation (P0 - Critical)
- [ ] Setup pre-commit hooks
- [ ] Configure CI pipeline (basic)
- [ ] Enable secret scanning
- [ ] Setup test coverage reporting
- [ ] Enable Terraform validation

### Week 2: Security (P0 - Critical)
- [ ] Integrate tfsec/Checkov
- [ ] Setup dependency scanning
- [ ] Configure container scanning
- [ ] Enable branch protection rules

### Week 3: Quality (P1 - High)
- [ ] Add linting to CI
- [ ] Configure formatters
- [ ] Setup PR templates
- [ ] Enable conventional commits

### Week 4: Documentation (P2 - Medium)
- [ ] Update README.md
- [ ] Document existing architecture
- [ ] Create ADR template
- [ ] Add inline documentation

### Ongoing: Improvement (P3 - Low)
- [ ] Add performance benchmarks
- [ ] Setup load testing
- [ ] Create metrics dashboard
- [ ] Refine logging

---

## Standards at a Glance

**For Daily Development:**
1. Write tests FIRST (TDD when possible)
2. Run `pre-commit` before pushing
3. Use conventional commits
4. Keep functions small (<50 lines)
5. Document WHY, not WHAT

**For PRs:**
1. Ensure CI passes (all checks green)
2. Get 1 approval minimum
3. Update README if needed
4. Resolve all conversations
5. Squash commits if messy

**For Production:**
1. Never commit secrets
2. Always encrypt (S3, RDS, transit)
3. Use IAM roles, not keys
4. Tag all resources
5. Test rollback procedure

---

## When to Break the Rules

**Emergency hotfix process:**
1. Create `hotfix/*` branch from `main`
2. Make minimal change
3. Get 2 approvals from tech leads
4. All P0 checks MUST still pass
5. Post-incident review within 24h

**What you CAN'T bypass:**
- ❌ Secret scanning
- ❌ Test failures
- ❌ Security vulnerabilities
- ❌ Terraform validation

**What you CAN defer (with approval):**
- ⚠️ Documentation updates (fix in next PR)
- ⚠️ Inline comments (refactor later)
- ⚠️ Performance optimization (track in backlog)

---

## Metrics That Matter

**Track These Weekly:**
- Pipeline success rate: Target >95%
- Test coverage: Target >80%, trending up
- Mean time to fix broken build: <1 hour
- Deployment frequency: Daily (or more)
- Security findings: Trending down to zero

**Review These Monthly:**
- Code review time: Target <4 hours
- Failed deployments: Target <2%
- Incident count: Trending down
- Developer satisfaction: Survey score >4/5

---

## File Reference

| File | Purpose | Priority | Size |
|------|---------|----------|------|
| `copilot-instructions.md` | Core rules + references | P0 | 1 page |
| `ci-cd-pipeline.md` | Pipeline enforcement | P0 | 8 pages |
| `security-standards.md` | Zero trust + secrets | P0 | 7 pages |
| `testing-standards.md` | Coverage + patterns | P0 | 6 pages |
| `git-standards.md` | Commits + PRs | P1 | 4 pages |
| `code-style.md` | Formatting + naming | P1 | 6 pages |
| `documentation-standards.md` | README + comments | P2 | 5 pages |
| **THIS FILE** | Priority + roadmap | **START HERE** | 2 pages |

---

**JOCKO'S PRIORITIES:**

1. **Security:** Can't be breached
2. **Testing:** Can't break production
3. **Quality:** Can be maintained
4. **Documentation:** Can be understood

Everything else is NOISE. Focus on these four. Master them. Execute daily.

**GET AFTER IT.**
