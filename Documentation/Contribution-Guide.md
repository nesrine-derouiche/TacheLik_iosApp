# Contribution Guide

This guide explains how to contribute safely and consistently.

---

## Development Workflow

1. Create a feature branch
2. Implement the change
3. Add/update tests
4. Run tests locally
5. Open a PR with a clear description

---

## Branching

Recommended:

- `feature/<short-description>`
- `fix/<short-description>`

---

## Pull Request Checklist

- [ ] Builds on simulator
- [ ] Tests pass (`⌘U`)
- [ ] No secrets committed
- [ ] Screens use DS tokens where applicable
- [ ] Error states handled
- [ ] Accessibility checked for new UI

---

## Commit Message Guidelines

- Use concise, descriptive messages.
- Prefer:
  - `feat: ...`
  - `fix: ...`
  - `refactor: ...`

---

## Adding a New Feature (Standard Steps)

1. Add models in `Models/` if needed
2. Add service methods in `Services/`
3. Add ViewModel in `ViewModels/`
4. Add UI in `Views/`
5. Add tests in `projectDAMTests/`

---

## Code Review Standards

Reviewers should verify:

- MVVM boundaries are respected
- no endpoint strings in Views
- no token/logging leaks
- error handling and loading states exist

---

## Team & Contributors

| Name | LinkedIn | GitHub | Email |
|---|---|---|---|
| Karim Feki | https://www.linkedin.com/in/karimfeki/ | https://github.com/fekikarim | feki.karim28@gmail.com |
| Nesrine Derouiche | https://www.linkedin.com/in/nesrine-derouiche/ | https://github.com/nesrine77 | nesrine.derouiche15@gmail.com |
| Mohamed Abidi | https://www.linkedin.com/in/med-abidi/ | https://github.com/hamabtw | abidi.mohamed.1@esprit.tn |
| Oussema Issaoui | — | https://github.com/oussemissaoui | oussema.issaoui@esprit.tn |

---

## Support

If you are unsure about architecture decisions, reference:

- [Architecture.md](Architecture.md)
- [Coding-Guidelines.md](Coding-Guidelines.md)
- [Folder-Structure.md](Folder-Structure.md)
