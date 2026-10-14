@echo off
rem https://superuser.com/questions/150244/command-aliases-in-command-prompt
rem DOSKEY macros only last for the current console session.
echo Setting MJS aliases - type 'alias' to see options
DOSKEY ls=DIR $*
DOSKEY cp=COPY $*
DOSKEY xcp=XCOPY $*
DOSKEY mv=MOVE $*
DOSKEY clear=CLS
DOSKEY h=DOSKEY /HISTORY
rem 'alias' with no args lists all macros; with args it defines a new one.
DOSKEY alias=if ".$*." == ".." ( DOSKEY /MACROS ) else ( DOSKEY $* )
rem Claude Code mouse click handling: 0 (set here) keeps it enabled; set to 1
rem to disable it so terminal-native click behavior (text selection, etc.)
rem keeps working.
set CLAUDE_CODE_DISABLE_MOUSE_CLICKS=0
