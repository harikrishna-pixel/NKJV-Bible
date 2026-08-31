# IMPORTANT_RULES.md

## 🚨 Non-Negotiable Rules

These rules apply to **every task** unless I explicitly say otherwise.

### Scope

* Only implement what I asked.
* Do not make unrelated changes.
* If another file seems necessary, **stop and ask for approval first.**

### Before Editing

Before writing any code:

1. List every file you intend to modify.
2. Explain why each file needs to change.
3. Wait for my approval.

If additional files become necessary later:

* Stop.
* Explain why.
* Wait for approval.

---

## Protect Existing Code

Do **NOT** modify any unrelated:

* Business logic
* UI
* Widgets
* Screens
* Navigation
* Services
* Providers
* Controllers
* Repositories
* Models
* Utilities
* Themes
* Routing
* Configuration

If the task doesn't require changing them, leave them untouched.

---

## No Refactoring

Unless I explicitly ask:

* Do not refactor.
* Do not optimize.
* Do not clean up code.
* Do not rename anything.
* Do not reorganize files.
* Do not change architecture.
* Do not change state management.
* Do not improve unrelated code.

---

## UI Protection

Do not change:

* Layout
* Colors
* Fonts
* Spacing
* Animations
* Styling
* User experience
* Navigation flow

unless I specifically request it.

---

## Logic Protection

Never change existing logic just because you think it can be improved.

Always preserve the current behavior unless the requested task requires changing it.

---

## Fixes

When fixing a bug:

* Find the root cause.
* Implement the **smallest possible fix**.
* Do not rewrite the feature.
* Do not introduce new architecture.
* Do not change unrelated code.

---

## Investigation

Never assume.

Verify with code and runtime evidence before making changes.

If multiple causes exist, explain them before choosing a fix.

---

## Final Report

After completing the task, always provide:

* Files modified
* Why each file was modified
* Root cause
* What changed
* Why the change is safe
* Confirmation that no unrelated logic or UI was modified

---

# Golden Rule

**The goal is to solve only the requested problem with the smallest possible change while preserving every existing feature, business logic, UI, navigation flow, and architecture. If any change falls outside the requested scope, stop and ask for approval first.**
