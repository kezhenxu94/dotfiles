---
description: create a git commit based on current changes
agent: build
model: opencode/big-pickle
---

Create a conventional commit for the current staged changes, if there is no staged files, ask users whether they want to stage all changes and create a commit.
DO NOT STAGE FILES by yourselve without users confirmation! Only inspect the staged changes.
Then create a commit with a proper conventional commit message following the conventional commits specification.
Use the same language as the previous commit messages.
