#!/usr/bin/env python3
"""Verify which OpenCode configuration documents are loaded, and which model
each agent resolves to in the current working directory.

OpenCode merges config from many sources (global, project, system). Reading the
file you edited tells you nothing about what was actually loaded. This asks the
running service for its effective state instead.

Usage:
    verify_config.py            report on the shared service's location
    verify_config.py --dir .    report on the current directory instead
    verify_config.py --json     raw JSON (config documents + agents)
    verify_config.py --quiet    exit 1 if a project config shadows the global one

`opencode api` binds to the shared background service, whose location is fixed
when that service starts -- it does NOT follow your current directory. For a
directory other than the service's location, pass --dir, which runs a private
standalone server bound to that directory.
"""

import json
import os
import subprocess
import sys

TARGET_DIR = None
STANDALONE = False

GLOBAL_DIR = os.path.expanduser("~/.config/opencode")
GLOBAL_FILES = {os.path.join(GLOBAL_DIR, "opencode.json"),
                os.path.join(GLOBAL_DIR, "opencode.jsonc")}
LOG = os.path.expanduser("~/.local/share/opencode/log/opencode.log")

USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def c(text, code):
    return f"\033[{code}m{text}\033[0m" if USE_COLOR else str(text)


def bold(t):   return c(t, "1")
def dim(t):    return c(t, "2")
def green(t):  return c(t, "32")
def yellow(t): return c(t, "33")
def red(t):    return c(t, "31")
def cyan(t):   return c(t, "36")


def api(path):
    cmd = ["opencode", "api", "get", path]
    if STANDALONE:
        cmd.append("--standalone")
    proc = subprocess.run(cmd, capture_output=True, text=True,
                          cwd=TARGET_DIR or None)
    if proc.returncode != 0:
        raise RuntimeError(f"`{' '.join(cmd)}` failed:\n{proc.stderr.strip()}")
    if not proc.stdout.strip():
        raise RuntimeError(f"`{' '.join(cmd)}` returned nothing")
    return json.loads(proc.stdout)


def model_ref(model):
    """Normalise a model reference to 'provider/model' regardless of shape."""
    if not model:
        return None
    if isinstance(model, str):
        return model
    prov = model.get("providerID") or ""
    mid = model.get("model") or model.get("modelID") or model.get("id") or ""
    if not prov and "/" in mid:
        return mid
    return f"{prov}/{mid}".strip("/")


def section(title):
    print()
    print(bold(title))
    print(dim("-" * len(title)))


def derive_agents(documents):
    """Merge `agents` and top-level `model` across documents in precedence order.

    Used when the live agent registry is unavailable, which is the case for a
    freshly started standalone server.
    """
    declared = {}
    top_model = None
    for doc in documents:
        info = doc.get("info") or {}
        if info.get("model"):
            top_model = model_ref(info["model"])
        for name, spec in (info.get("agents") or {}).items():
            if not isinstance(spec, dict):
                continue
            if spec.get("model"):
                declared[name] = {"model": model_ref(spec["model"]),
                                  "mode": spec.get("mode"),
                                  "hidden": spec.get("hidden")}
            else:
                prev = declared.get(name) or {}
                declared[name] = {**prev,
                                  "mode": spec.get("mode", prev.get("mode")),
                                  "hidden": spec.get("hidden", prev.get("hidden"))}
    return declared, top_model


def main():
    global TARGET_DIR, STANDALONE

    argv = [a for a in sys.argv[1:]]
    if "-h" in argv or "--help" in argv:
        print((__doc__ or "").strip())
        return 0
    if "--dir" in argv:
        i = argv.index("--dir")
        if i + 1 >= len(argv):
            print(red("error: --dir needs a path"), file=sys.stderr)
            return 2
        TARGET_DIR = os.path.abspath(os.path.expanduser(argv[i + 1]))
        STANDALONE = True
        del argv[i:i + 2]

    json_mode = "--json" in argv
    quiet = "--quiet" in argv

    try:
        cfg = api("/api/config")
        agents_doc = api("/api/agent")
        default_model = api("/api/model/default")
    except RuntimeError as exc:
        print(red(f"error: {exc}"), file=sys.stderr)
        return 2

    documents = [d for d in cfg if d.get("type") == "document"]
    agents = agents_doc.get("data") or []
    directory = (cfg[0].get("location", {}) if cfg else {}).get("directory") \
        or agents_doc.get("location", {}).get("directory") \
        or os.getcwd()

    if json_mode:
        print(json.dumps({"directory": directory,
                          "documents": documents,
                          "agents": agents,
                          "default_model": default_model.get("data")},
                         indent=2))
        return 0

    # ---- header -----------------------------------------------------
    print(bold("OpenCode effective configuration"))
    print(f"  directory : {cyan(directory)}")
    if STANDALONE:
        print(f"  mode      : {dim('standalone server bound to --dir')}")
    elif os.path.abspath(os.getcwd()) != os.path.abspath(directory):
        print(f"  {yellow('note')}      : shared service lives in {directory}, "
              f"not {os.getcwd()}")
        print(f"              {dim('use --dir . to inspect the current directory')}")

    dm = default_model.get("data") or {}
    print(f"  model     : {cyan(model_ref(dm) or '-')}  "
          f"{dim('(' + dm.get('name', '') + ')') if dm.get('name') else ''}")

    # ---- documents --------------------------------------------------
    section("Config documents (merge order, lowest to highest precedence)")
    if not documents:
        print(yellow("  no config documents loaded"))

    overrides = []
    for i, doc in enumerate(documents):
        path = doc.get("path")
        info = doc.get("info") or {}
        label = path or f"{dim('(built-in defaults)')}"
        is_global = path in GLOBAL_FILES
        is_project = path is not None and not is_global

        if is_global:
            tag = green("global")
        elif is_project:
            tag = yellow("PROJECT OVERRIDE")
            overrides.append(path)
        else:
            tag = dim("built-in")

        print(f"  [{i}] {label}  {tag}")

        mdl = model_ref(info.get("model"))
        if mdl:
            print(f"       model         : {mdl}")
        if info.get("small_model"):
            print(f"       small_model   : {info['small_model']}  "
                  f"{yellow('(deprecated in V2)')}")
        if info.get("default_agent"):
            print(f"       default_agent : {info['default_agent']}")
        if info.get("agents"):
            print(f"       agents        : {', '.join(info['agents'])}")

    # ---- agents -----------------------------------------------------
    if agents:
        section("Agents (live registry)")
        width = max((len(a.get("id", "")) for a in agents), default=10)
        for a in sorted(agents, key=lambda x: (x.get("hidden", False), x.get("id", ""))):
            ref = model_ref(a.get("model"))
            hidden = a.get("hidden")
            mode = a.get("mode") or "?"
            if ref:
                shown = cyan(ref)
            else:
                shown = dim("inherits session model")
            marks = []
            if hidden:
                marks.append(dim("hidden"))
            if mode:
                marks.append(dim(mode))
            print(f"  {a.get('id', ''):<{width}}  {shown:<32} {' '.join(marks)}")
    else:
        section("Agents (derived from the loaded documents)")
        print(dim("  the standalone registry is empty, so these are what the"))
        print(dim("  documents declare, merged in precedence order."))
        declared, top_model = derive_agents(documents)
        if not declared:
            print(yellow("  no agent definitions found"))
        width = max((len(n) for n in declared), default=10)
        for name in sorted(declared, key=lambda n: (declared[n].get("hidden") is True, n)):
            spec = declared[name]
            ref = spec.get("model")
            shown = cyan(ref) if ref else dim(f"top-level model ({top_model or 'unset'})")
            marks = []
            if spec.get("hidden"):
                marks.append(dim("hidden"))
            if spec.get("mode"):
                marks.append(dim(spec["mode"]))
            print(f"  {name:<{width}}  {shown:<32} {' '.join(marks)}")

    # ---- diagnosis --------------------------------------------------
    section("Diagnosis")
    if overrides:
        print(yellow("  A project config shadows your global settings:"))
        for p in overrides:
            print(f"    - {p}")
        print(dim("  These load after ~/.config/opencode and win on conflict."))
    else:
        print(green("  No project config found. The global config is authoritative here."))

    for bad in agents:
        if not model_ref(bad.get("model")) and bad.get("id") not in ("general",):
            pass  # inheriting is legitimate for subagents

    # stale session note
    try:
        sessions = api("/api/session")
        items = sessions.get("data") if isinstance(sessions, dict) else sessions
        items = items or []
        if items:
            print(dim(f"  {len(items)} existing session(s) keep the model they were "
                      f"created with; start a new one to pick up new defaults."))
    except Exception:
        pass

    # ---- recent warnings -------------------------------------------
    if os.path.exists(LOG):
        try:
            with open(LOG, "r", errors="replace") as fh:
                tail = fh.readlines()[-400:]
        except OSError:
            tail = []
        hits = [ln.rstrip() for ln in tail
                if ("level=WARN" in ln or "level=ERROR" in ln)
                and any(k in ln.lower() for k in ("config", "agent", "model"))]
        section("Recent config warnings")
        if hits:
            for ln in hits[-6:]:
                print(f"  {yellow(ln[:200])}")
        else:
            print(green("  none"))

    print()
    if quiet:
        return 1 if overrides else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
