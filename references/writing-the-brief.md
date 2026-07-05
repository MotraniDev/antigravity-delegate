# Writing the brief

A brief is the entire task as `agy` will see it — no chat history, only the text you send plus the working tree (`GEMINI.md`, repo docs).

## Shape that works

```xml
<task>
Concrete job, location, what to change, what to leave untouched.
</task>

<verification_loop>
Run before finishing:
  <project test command>
  <project lint command>
</verification_loop>

<action_safety>
Scoped changes only. Do NOT git add or git commit.
</action_safety>

<structured_output_contract>
Report: (1) what changed, (2) files touched, (3) gate outcomes, (4) open questions.
</structured_output_contract>
```

Discover real gate commands from `AGENTS.md` / `Makefile` / `package.json`.

One brief → one `agy` run → one commit.
