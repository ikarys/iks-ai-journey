# How-to use SKILL file

## Install

Create a file SKILL.md in a specific folder to be able to use it

### Example
- Cursor : `.cursor/skills/git-smart-commit/SKILL.md`
- Pi : `~/.pi/agent/skills/git-smart-commit/SKILL.md` (global) ou `.pi/skills/git-smart-commit/SKILL.md` (projet)
- Claude Code : `~/.claude/skills/git-smart-commit/SKILL.md`

## Usage
In Cursor, Pi, or Claude Code, simply ask:  
- "Prepare the commits"  
- "What did I change? Suggest commits"  
- "Smart commit"  
Or use the slash command: /git-smart-commit  

The agent will automatically load the skill if the description matches.  
If it doesn’t, force it with /skill:git-smart-commit (Pi) or @file:.cursor/skills/git-smart-commit/SKILL.md (Cursor).
