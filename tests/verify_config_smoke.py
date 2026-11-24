#!/usr/bin/env python3
"""Cross-platform smoke test for the verify-config skill's script.

The script's failure mode is platform-specific: it shells out to the `opencode`
CLI, which npm installs on Windows as a .cmd shim that CreateProcess cannot find
by bare name. Nothing else in CI runs this script, so a regression there is
invisible until someone on the affected OS tries it.

A stub CLI stands in for the real one, so no service, network, or login is
needed. The stub answers the four endpoints the script calls, and reports its
config as living under XDG_CONFIG_HOME so the XDG handling is exercised too.

Run directly:  python tests/verify_config_smoke.py
Exit status:   0 if every check passes, 1 otherwise.
"""

import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.normpath(os.path.join(
    HERE, os.pardir, "opencode", "skills", "verify-config", "scripts",
    "verify_config.py"))

# The fake CLI. It reads the endpoint off argv and prints the JSON shape the
# real service returns. STUB_PROJECT adds a second config document so the
# shadowing-detection path can be tested.
STUB_SOURCE = '''\
import json
import os
import sys

endpoint = sys.argv[-1].rstrip("/") if len(sys.argv) > 1 else ""
cfg_home = os.environ.get("XDG_CONFIG_HOME", "")
global_doc = os.path.join(cfg_home, "opencode", "opencode.jsonc")

if endpoint.endswith("/api/config"):
    payload = [
        {"type": "document", "path": None,
         "info": {"providers": ["stub"]}},
        {"type": "document", "path": global_doc,
         "info": {"model": {"providerID": "stubprov", "model": "stub-model"},
                  "default_agent": "stub-agent",
                  "agents": {"stub-agent": {}}}},
    ]
    if os.environ.get("STUB_PROJECT"):
        payload.append({
            "type": "document",
            "path": os.path.join(os.getcwd(), "opencode.jsonc"),
            "info": {"model": {"providerID": "stubprov",
                               "model": "project-model"}},
        })
elif endpoint.endswith("/api/agent"):
    payload = {"data": [
        {"id": "stub-agent", "mode": "primary", "hidden": False,
         "model": {"id": "stub-model", "providerID": "stubprov"}},
        {"id": "helper", "mode": "subagent", "hidden": True},
    ]}
elif endpoint.endswith("/api/model/default"):
    payload = {"data": {"id": "stub-model", "providerID": "stubprov",
                        "name": "Stub Model"}}
elif endpoint.endswith("/api/session"):
    payload = {"data": []}
else:
    sys.stderr.write("stub: unknown endpoint %r\\n" % (endpoint,))
    sys.exit(1)

print(json.dumps(payload))
'''

failures = []


def check(condition, description):
    print(("  ok    " if condition else "  FAIL  ") + description)
    if not condition:
        failures.append(description)


def write_stub_cli(directory):
    """Install a fake `opencode` so the script can be run end to end."""
    stub = os.path.join(directory, "stub_cli.py")
    with open(stub, "w", encoding="utf-8") as handle:
        handle.write(STUB_SOURCE)

    interpreter = sys.executable or "python3"
    if os.name == "nt":
        # A .cmd shim, exactly like npm installs: the case that used to break.
        shim = os.path.join(directory, "opencode.cmd")
        with open(shim, "w", encoding="utf-8", newline="\r\n") as handle:
            handle.write('@echo off\n"%s" "%s" %%*\n' % (interpreter, stub))
    else:
        shim = os.path.join(directory, "opencode")
        with open(shim, "w", encoding="utf-8") as handle:
            handle.write('#!/bin/sh\nexec "%s" "%s" "$@"\n'
                         % (interpreter, stub))
        os.chmod(shim, 0o755)
    return shim


def make_env(stub_dir, home, workdir, extra=None):
    """A clean environment: only the stub CLI on PATH, throwaway HOME/XDG."""
    env = dict(os.environ)
    env["NO_COLOR"] = "1"
    env["PATH"] = stub_dir if stub_dir else home  # home is empty: no CLI
    env["HOME"] = home
    env["XDG_CONFIG_HOME"] = os.path.join(home, ".config")
    env["XDG_DATA_HOME"] = os.path.join(home, ".local", "share")
    if os.name == "nt":
        # expanduser("~") reads USERPROFILE, not HOME.
        env["USERPROFILE"] = home
        env["APPDATA"] = os.path.join(home, "AppData", "Roaming")
    for name in ("OBSIDIAN_VAULT", "STUB_PROJECT"):
        env.pop(name, None)
    env.update(extra or {})
    return env


def run(args, env, workdir):
    return subprocess.run(
        [sys.executable, SCRIPT] + args,
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        env=env, cwd=workdir)


def main():
    print("verify-config smoke test")
    print("  script: %s" % SCRIPT)
    print("  python: %s (%s)" % (sys.executable, sys.platform))

    if not os.path.isfile(SCRIPT):
        print("FAIL: script not found")
        return 1

    stub_dir = tempfile.mkdtemp(prefix="vc-stub-")
    home = tempfile.mkdtemp(prefix="vc-home-")
    workdir = tempfile.mkdtemp(prefix="vc-cwd-")
    write_stub_cli(stub_dir)
    env = make_env(stub_dir, home, workdir)

    print("\n1. report (stub CLI resolved from PATH)")
    proc = run([], env, workdir)
    out = proc.stdout
    check(proc.returncode == 0, "exit code 0 (got %d)" % proc.returncode)
    if proc.returncode != 0:
        print(proc.stderr.strip()[:800])
    check("stub-agent" in out, "agent registry rendered")
    check("stubprov/stub-model" in out, "agent model resolved")
    check("global" in out, "global document tagged")
    check("No project config found" in out, "no false project override")

    print("\n2. --json")
    proc = run(["--json"], env, workdir)
    check(proc.returncode == 0, "exit code 0")
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = None
    check(isinstance(payload, dict), "stdout is JSON")
    if isinstance(payload, dict):
        check(len(payload.get("documents") or []) == 2, "two documents")
        check(len(payload.get("agents") or []) == 2, "two agents")
        model = (payload.get("default_model") or {}).get("id")
        check(model == "stub-model", "default model resolved (%s)" % model)

    print("\n3. --quiet with a project config shadowing the global one")
    proc = run(["--quiet"], make_env(stub_dir, home, workdir,
                                     {"STUB_PROJECT": "1"}), workdir)
    check(proc.returncode == 1, "exit code 1 (got %d)" % proc.returncode)
    check("PROJECT OVERRIDE" in proc.stdout, "override reported")

    print("\n4. --quiet with no override")
    proc = run(["--quiet"], env, workdir)
    check(proc.returncode == 0, "exit code 0 (got %d)" % proc.returncode)

    print("\n5. no CLI on PATH")
    proc = run([], make_env(None, home, workdir), workdir)
    check(proc.returncode == 2, "exit code 2 (got %d)" % proc.returncode)
    check("cannot find the `opencode` CLI" in proc.stderr,
          "clear error instead of a traceback")
    check("Traceback" not in proc.stderr, "no traceback")

    print("\n6. --help")
    proc = run(["--help"], env, workdir)
    check(proc.returncode == 0, "exit code 0")
    check("verify_config.py" in proc.stdout, "usage printed")

    print()
    if failures:
        print("FAILED: %d check(s)" % len(failures))
        for item in failures:
            print("  - " + item)
        return 1
    print("all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
