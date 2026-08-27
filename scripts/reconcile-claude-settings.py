#!/usr/bin/env python3
"""Centrally reconcile Claude settings used by dotfiles-managed tools.

Dotfiles is the sole owner of the declared directory grants and tool hooks.
Unrelated settings are preserved. A separate state file records only the
entries this reconciler owns so removed declarations can be retracted safely.
"""

import argparse
import json
import os
import sys
import tempfile

HOOK_EVENT = "UserPromptSubmit"
HOOK_RELATIVE_PATH = os.path.join("scripts", "cadence.sh")


def fail(message):
    print("error: %s" % message, file=sys.stderr)
    return 1


def load_object(path, missing=None):
    if not os.path.exists(path):
        return {} if missing is None else missing
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError("%s is not valid JSON: %s" % (path, error))
    if not isinstance(data, dict):
        raise ValueError("%s has a non-object top level" % path)
    return data


def atomic_write(path, data):
    directory = os.path.dirname(os.path.abspath(path))
    os.makedirs(directory, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".reconcile.", dir=directory)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False)
            handle.write("\n")
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def normalized(path):
    return os.path.normpath(path)


def unique_paths(paths):
    result = []
    seen = set()
    for path in paths:
        key = normalized(path)
        if key not in seen:
            result.append(path)
            seen.add(key)
    return result


def settings_directories(settings, settings_path):
    permissions = settings.get("permissions")
    if permissions is None:
        permissions = {}
        settings["permissions"] = permissions
    elif not isinstance(permissions, dict):
        raise ValueError("%s has non-object permissions" % settings_path)

    directories = permissions.get("additionalDirectories")
    if directories is None:
        directories = []
        permissions["additionalDirectories"] = directories
    elif not isinstance(directories, list) or not all(
        isinstance(item, str) for item in directories
    ):
        raise ValueError("%s has invalid permissions.additionalDirectories" % settings_path)
    return directories


def remove_directories(settings, paths):
    permissions = settings.get("permissions")
    if not isinstance(permissions, dict):
        return 0
    directories = permissions.get("additionalDirectories")
    if not isinstance(directories, list):
        return 0

    unwanted = {normalized(path) for path in paths}
    kept = [
        path
        for path in directories
        if not isinstance(path, str) or normalized(path) not in unwanted
    ]
    removed = len(directories) - len(kept)
    if not removed:
        return 0
    if kept:
        permissions["additionalDirectories"] = kept
    else:
        permissions.pop("additionalDirectories", None)
        if not permissions:
            settings.pop("permissions", None)
    return removed


def hook_command(worklog_path):
    return os.path.join(worklog_path, HOOK_RELATIVE_PATH)


def settings_matchers(settings, settings_path):
    hooks = settings.get("hooks")
    if hooks is None:
        hooks = {}
        settings["hooks"] = hooks
    elif not isinstance(hooks, dict):
        raise ValueError("%s has non-object hooks" % settings_path)

    matchers = hooks.get(HOOK_EVENT)
    if matchers is None:
        matchers = []
        hooks[HOOK_EVENT] = matchers
    elif not isinstance(matchers, list):
        raise ValueError("%s has invalid hooks.%s" % (settings_path, HOOK_EVENT))
    return matchers


def matcher_has_command(matcher, command):
    if not isinstance(matcher, dict):
        return False
    entries = matcher.get("hooks")
    if not isinstance(entries, list):
        return False
    want = normalized(command)
    return any(
        isinstance(entry, dict)
        and isinstance(entry.get("command"), str)
        and normalized(entry["command"]) == want
        for entry in entries
    )


def add_hook(settings, settings_path, command):
    matchers = settings_matchers(settings, settings_path)
    if any(matcher_has_command(matcher, command) for matcher in matchers):
        return False
    matchers.append({"hooks": [{"type": "command", "command": command}]})
    return True


def remove_hooks(settings, commands):
    hooks = settings.get("hooks")
    if not isinstance(hooks, dict):
        return 0
    matchers = hooks.get(HOOK_EVENT)
    if not isinstance(matchers, list):
        return 0

    unwanted = {normalized(command) for command in commands}
    removed = 0
    kept_matchers = []
    for matcher in matchers:
        if not isinstance(matcher, dict):
            kept_matchers.append(matcher)
            continue
        entries = matcher.get("hooks")
        if not isinstance(entries, list):
            kept_matchers.append(matcher)
            continue
        kept_entries = []
        for entry in entries:
            command = entry.get("command") if isinstance(entry, dict) else None
            if isinstance(command, str) and normalized(command) in unwanted:
                removed += 1
            else:
                kept_entries.append(entry)
        if kept_entries:
            matcher["hooks"] = kept_entries
            kept_matchers.append(matcher)
        else:
            other = {key: value for key, value in matcher.items() if key != "hooks"}
            if other:
                matcher["hooks"] = []
                kept_matchers.append(matcher)

    if removed:
        if kept_matchers:
            hooks[HOOK_EVENT] = kept_matchers
        else:
            hooks.pop(HOOK_EVENT, None)
            if not hooks:
                settings.pop("hooks", None)
    return removed


def parse_state(path):
    state = load_object(path)
    directories = state.get("ownedDirectories", [])
    hooks = state.get("ownedHooks", [])
    if not isinstance(directories, list) or not all(isinstance(item, str) for item in directories):
        raise ValueError("%s has invalid ownedDirectories" % path)
    if not isinstance(hooks, list) or not all(isinstance(item, str) for item in hooks):
        raise ValueError("%s has invalid ownedHooks" % path)
    return directories, hooks


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", required=True)
    parser.add_argument("--state", required=True)
    parser.add_argument("--worklog", required=True)
    parser.add_argument("--directory", action="append", default=[])
    parser.add_argument("--hook", action="append", default=[])
    parser.add_argument("--preserve-owned-directories", action="store_true")
    return parser.parse_args(argv[1:])


def main(argv):
    args = parse_args(argv)
    desired_directories = unique_paths([args.worklog] + args.directory)
    desired_hooks = unique_paths([hook_command(args.worklog)] + args.hook)

    try:
        settings = load_object(args.settings)
        previous_directories, previous_hooks = parse_state(args.state)
        if args.preserve_owned_directories:
            desired_directories = unique_paths(desired_directories + previous_directories)
        directories = settings_directories(settings, args.settings)
        settings_matchers(settings, args.settings)
    except ValueError as error:
        return fail("%s; refusing to overwrite" % error)

    for path in desired_directories:
        if not os.path.isabs(path):
            return fail("directory must be absolute: %s" % path)
    if not os.path.isabs(args.worklog):
        return fail("worklog path must be absolute: %s" % args.worklog)
    for command in desired_hooks:
        if not os.path.isabs(command):
            return fail("hook command must be absolute: %s" % command)

    desired_directory_keys = {normalized(path) for path in desired_directories}
    desired_hook_keys = {normalized(command) for command in desired_hooks}
    stale_directories = [
        path for path in previous_directories if normalized(path) not in desired_directory_keys
    ]
    stale_hooks = [
        command for command in previous_hooks if normalized(command) not in desired_hook_keys
    ]

    removed_directories = remove_directories(settings, stale_directories)
    removed_hooks = remove_hooks(settings, stale_hooks)

    directories = settings_directories(settings, args.settings)
    present = {normalized(path) for path in directories}
    added_directories = 0
    for path in desired_directories:
        if normalized(path) not in present:
            directories.append(path)
            present.add(normalized(path))
            added_directories += 1
    added_hooks = sum(add_hook(settings, args.settings, command) for command in desired_hooks)

    state = {
        "ownedDirectories": desired_directories,
        "ownedHooks": desired_hooks,
    }
    try:
        atomic_write(args.settings, settings)
        atomic_write(args.state, state)
    except OSError as error:
        return fail("could not write reconciled state: %s" % error)

    print(
        json.dumps(
            {
                "addedDirectories": added_directories,
                "removedDirectories": removed_directories,
                "addedHooks": added_hooks,
                "removedHooks": removed_hooks,
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
