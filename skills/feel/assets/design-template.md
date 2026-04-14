# Design: {feature-name}

<!--
FORMAT IS PROTOCOL: Use these exact bold-asterisk fields. Do NOT convert to
YAML frontmatter (---/---) even if the project's other files use YAML.
/think's orient script parses these fields to detect ready design docs.
-->

**Type:** design
**Created:** {date}
**Status:** draft | ready | consumed | cancelled
**Session:** {feature-name}.{n}
**Cardinality:** mono | multi
**Slices:** {empty for mono; comma-separated slice IDs for multi, e.g. jwt-middleware, login-endpoint, password-reset}
**Desc:** {single-line summary — the outcome in user terms}

---

## Goal

{What we're building and why. The problem it solves. 2-3 sentences max.}

## Scope

**In:**
- {what's included}

**Out:**
- {what's explicitly excluded and why}

## Approach

{The chosen approach and why it was chosen over alternatives. Include enough reasoning that a fresh /think session won't second-guess it.}

## Open Questions

> /think resolves these through research. Each should say what kind of answer is needed.

- {question} — needs: {codebase pattern / external best practice / user decision / research}

> If none: "None — ready to spec."

---

> The sections below are optional. Include when the /feel conversation produced them. Don't manufacture content for empty sections.

## Motivation

{What triggered this work. User need, pain point, opportunity, incident. Why now.}

## Approaches Considered

### {Approach A} (chosen)
{Why it was chosen.}

### {Approach B} (rejected)
{Why it was rejected. What would change to make it viable.}

## Key Decisions

- **{Decision}** — {rationale}

## Constraints

- {constraint — hard limits that can't be negotiated}

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| {risk} | {what breaks} | {how to address} |

## Success Criteria

> In user-facing terms, not implementation terms. /think translates these into technical Done Criteria.

- {criterion}

## Notes

{Freeform catch-all for insights that don't fit other sections.}
