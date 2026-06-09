# Pending Windows fixes (from 2026-06-09 code review)

Apply these on a Windows machine, then test and delete this file.

## 1. deploy.bat — escape parens in echo (likely breaks all deployment)

`deploy.bat` line 18, inside the `if not exist` block:

```bat
echo   SKIP %~nx1 (not found)
```

The unescaped `)` closes the `if` block early at parse time, which leaves the
following `goto :eof` OUTSIDE the block — so `:backup_and_copy` returns
unconditionally and never copies anything. Fix by escaping both parens:

```bat
echo   SKIP %~nx1 ^(not found^)
```

After fixing, run `deploy.bat` and confirm it actually prints
INSTALLED/UNCHANGED lines and that `%USERPROFILE%\.emacs` and
`%USERPROFILE%\aliases.bat` get created/updated.

## 2. deploy.bat — add setlocal

There is no `setlocal`, so `src`/`dest` leak into the cmd session after the
script runs. Add `setlocal` on the line after `@echo off`.

## 3. Windows/netlogon.bat — quieter, idiomatic delay (minor)

Replace the ping-based delay:

```bat
set delay=10
ping localhost -n %delay%
```

with:

```bat
timeout /t 9 /nobreak >nul
```

(or keep ping but append `>nul` to suppress ten lines of output in the
logon console).

## Notes

- `.gitattributes` forces CRLF for `*.bat` — edit normally, git handles it.
- When done: delete this file, commit, push (branch -> ff-only merge to
  master workflow).
