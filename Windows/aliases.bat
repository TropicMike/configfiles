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
rem Disable mouse click handling in Claude Code so terminal-native click
rem behavior (text selection, etc.) keeps working.
set CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1
