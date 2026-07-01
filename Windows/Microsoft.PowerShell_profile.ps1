# PowerShell equivalents of the shared .aliases, plus the same colored prompt
# as the bash/zsh configs. Deployed by deploy.bat to $PROFILE.CurrentUserCurrentHost
# for both Windows PowerShell 5.1 and PowerShell 7 (pwsh), so keep everything
# 5.1-compatible (no ternary, no && / || pipeline chains).

# Editor: GUI Emacs (runemacs, doesn't block the console) -> console emacs ->
# notepad fallback. EDITOR is set for tools like git; `e` is the shortcut.
if (Get-Command runemacs -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'runemacs'
    Set-Alias -Name e -Value runemacs
} elseif (Get-Command emacs -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'emacs'
    Set-Alias -Name e -Value emacs
} else {
    $env:EDITOR = 'notepad'
    Set-Alias -Name e -Value notepad
}

# Command shortcuts mirroring .aliases. md/mkdir, h (history), cp, mv, and ls
# already exist as PowerShell built-in aliases, so only the gaps are filled.
Set-Alias -Name z -Value Clear-Host
Set-Alias -Name hex -Value Format-Hex

# Pager: Git for Windows ships less.exe; fall back to more.
if (Get-Command less -ErrorAction SilentlyContinue) {
    Set-Alias -Name m -Value less
} else {
    Set-Alias -Name m -Value more
}

# Long listing including hidden files, newest first, paged (like `ls -lath | less`).
function lsd { Get-ChildItem -Force | Sort-Object LastWriteTime -Descending | more }

# Delete Emacs backup (*~) and autosave (#*#) files in the current directory.
function rmbak { Remove-Item -Path '*~', '#*#' -ErrorAction SilentlyContinue }

# Print each interface and its IPv4 address.
function ipa {
    Get-NetIPAddress -AddressFamily IPv4 |
        Sort-Object -Property InterfaceAlias |
        Format-Table -Property InterfaceAlias, IPAddress -AutoSize
}

# Prompt: user@host:dir>  -- username red when elevated / green otherwise
# (visual warning that you're admin), hostname yellow, dir blue; matches the
# bash/zsh prompts. Also sets the window title to the hostname each prompt.
function prompt {
    $Host.UI.RawUI.WindowTitle = $env:COMPUTERNAME
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $elevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($elevated) { $userColor = 'Red' } else { $userColor = 'Green' }
    Write-Host "$env:USERNAME@" -NoNewline -ForegroundColor $userColor
    Write-Host $env:COMPUTERNAME -NoNewline -ForegroundColor Yellow
    Write-Host ':' -NoNewline
    $dir = Split-Path -Path (Get-Location).Path -Leaf
    Write-Host $dir -NoNewline -ForegroundColor Blue
    return '> '
}

# Check whether the configfiles repo has new upstream commits and print a
# pull + deploy reminder (mirrors the check in .aliases). To avoid delaying
# shell startup with a network round-trip, compare against the refs from the
# LAST fetch (instant), then kick off a detached background fetch so the next
# shell sees fresh refs. No-op on machines without the repo cloned.
$cfgRepo = Join-Path $HOME 'Repos\configfiles'
if (-not (Test-Path (Join-Path $cfgRepo '.git'))) { $cfgRepo = 'C:\Repos\configfiles' }
if ((Test-Path (Join-Path $cfgRepo '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    # Resolve the remote's default branch (origin/HEAD, set at clone time)
    # rather than hardcoding master, so a rename to main keeps working.
    $def = git -C $cfgRepo rev-parse --abbrev-ref origin/HEAD 2>$null
    if (-not $def) { $def = 'origin/master' }
    $n = git -C $cfgRepo rev-list --count "HEAD..$def" 2>$null
    if ([int]$n -gt 0) {
        Write-Host "configfiles: $n new commit(s) upstream - run: git -C $cfgRepo pull; & $cfgRepo\deploy.bat" -ForegroundColor Yellow
    }
    Start-Process -FilePath git -ArgumentList '-C', $cfgRepo, 'fetch', '-q' -WindowStyle Hidden
}
Remove-Variable -Name cfgRepo, def, n -ErrorAction SilentlyContinue
