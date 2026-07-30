# eToro GitHub source hunt (Grok + Composer)

## Repos audited (official)

| Org/Repo | What it is | P1/P2? |
|----------|------------|--------|
| [eToro-Public/etoro-cursor-plugin](https://github.com/eToro-Public/etoro-cursor-plugin) | Cursor skills/rules for Public API + SSO | **No** |
| [eToro-Public/etoro-agent-skills](https://github.com/eToro-Public/etoro-agent-skills) | Agent trading / agent-portfolio skills | **No** |
| [eToro-API/examples](https://github.com/eToro-API/examples) | Legacy HTML/C# samples (placeholders only) | **No** |

Clones: `/workspace/vendor/etoro-github/` (gitignored vendor; reports under `research/etoro/github-source/`).

## Notable items (not P1/P2)

1. **Published partner `x-api-key`** in `etoro-agent-skills/.../api-conventions.md` — eToro labels it the **canonical Public API partner key**. Alone it does **not** authorize account access (`401` without per-user `x-user-key`). Treat as intentional public identifier, not a stolen secret.
2. **`cidList` vs `gcid` footgun** — documented by eToro: passing `gcid`/`demoCid` to `/user-info/people?cidList=` silently returns the **wrong** user. Integrator bug / public-profile mixup; they already warn in `etoro-sso-identity.mdc`. Not a novel server ATO.
3. Community MCP servers (gabrielcerutti, florinel-chis, etc.) — **third-party**, usually **out of Bugcrowd scope** unless you prove impact on eToro infra.

## Bottom line

GitHub source for eToro is mostly **docs/skills**, not the trading backend. **No hardcoded user keys / OAuth secrets / RCE** found that map to Bugcrowd P1/P2.
