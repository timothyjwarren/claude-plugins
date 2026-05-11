---
name: readme-writer
description: Writes user-focused README files for software projects. Use when the user asks to write, create, or update a README, document their project, or add documentation. Reads the codebase to infer content, confirms key details with the user, then writes README.md in one pass.
---

# Writing READMEs

Write README files that speak to the reader first -- not documentation, but a pitch and a guide. Every section answers an implicit question: "Why should I care, and what do I do next?"

## Process

### 1. Read the codebase

Scan for everything that reveals what the project does and how it works:

- Package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.
- Config and environment: `.env.example`, config files, CLI flag definitions
- Existing docs: `README.md`, `CHANGELOG`, `docs/`, wiki files
- CI/CD: `.github/workflows/`, `Makefile`, `Dockerfile`
- Source files: enough to understand the main entry point and core behavior

### 2. Form inferences

Before asking anything, develop a working hypothesis for each of these:

- **Audience** — who is this for? (e.g., backend developers, data scientists, ops teams, non-technical users)
- **Problem** — what pain does this solve? What does life look like without it?
- **Installation** — what are the prerequisites and steps?
- **Configuration** — what options exist, and which ones matter most?

### 3. Confirm with the user

Present your inferences, not blank questions. Lead with what you found:

> "It looks like this is aimed at Node.js developers who need to X. The main pain point seems to be Y. Does that sound right, or is there more to it?"

Only ask open-ended questions for things genuinely unknowable from the code (e.g., the emotional or business motivation behind the project). Aim for 2–4 confirmations total, one topic at a time.

### 4. Write README.md

Write in one pass using the structure below. If `README.md` already exists, ask before overwriting.

---

## README structure

### Problem
Paint the problem vividly before naming the solution. The goal is recognition — the reader should think "hey, I have that problem!" or "that's totally missing from my life."

This can be second-person ("Have you ever...") or just a clear description of the pain ("PR reviews pile up. They're easy to miss, easy to forget, and suddenly someone's been blocked for three days waiting on you."). No mention of the tool yet.

### Solution
Introduce the project by name. One or two sentences. No jargon.

### Benefits
Concrete, not abstract. Show what life looks like after adopting the tool.

- "You can do X in one command" — good
- "Improves developer experience" — too vague

### Installation
Step-by-step. Include prerequisites. Pull from package manifests, lockfiles, build scripts, and CI config -- don't invent steps. Distinguish required dependencies from optional ones: if a tool is used with a fallback or `|| true`, it's optional and should be labeled as such.

### Configuration
Show a minimal working example. Pull from `.env.example`, config files, or flag definitions. If the app is configured entirely through a UI, describe the UI flow instead -- no need to force a code block where none exists. Flag anything that commonly trips people up.

### Technical details _(if useful)_
A regular section at the end for architecture, internals, or anything only the curious need. Omit entirely if the project is simple enough that this section would just restate the obvious.

---

## Principles

- Write for the reader, not about the tool
- Earn attention in the problem section before asking for it in the installation section
- Prefer concrete examples over abstract descriptions
- Every sentence should justify its presence -- cut anything that doesn't help the reader decide to use the project or figure out how
- Use plain dashes (`--`) not em-dashes in prose
- Do not hard-wrap prose lines -- let lines flow naturally and only break at paragraph boundaries
