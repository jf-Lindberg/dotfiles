#!/usr/bin/env python3
"""Remove machine-specific home paths from an iTerm2 preferences export."""

import argparse
import os
import plistlib
import sys
import tempfile


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("plist")
    parser.add_argument("--home", required=True)
    return parser.parse_args()


def sanitize(value, home, key=None):
    if isinstance(value, dict):
        return {item_key: sanitize(item, home, item_key) for item_key, item in value.items()}
    if isinstance(value, list):
        return [sanitize(item, home, key) for item in value]
    if not isinstance(value, str):
        return value

    if key == "Working Directory":
        if value == home:
            return "~"
        if value.startswith(home + os.sep):
            return "~" + value[len(home) :]

    if value == home:
        return "$HOME"
    if value.startswith(home + os.sep):
        return "$HOME" + value[len(home) :]
    return value


def strings(value):
    if isinstance(value, dict):
        for item in value.values():
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)
    elif isinstance(value, str):
        yield value


def main():
    args = parse_args()
    home = os.path.normpath(os.path.abspath(os.path.expanduser(args.home)))

    try:
        with open(args.plist, "rb") as handle:
            preferences = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException) as error:
        sys.exit("sanitize-iterm2-plist: cannot read %s: %s" % (args.plist, error))

    sanitized = sanitize(preferences, home)
    remaining = [value for value in strings(sanitized) if home in value]
    if remaining:
        sys.exit(
            "sanitize-iterm2-plist: literal home path remains after sanitizing: %s" % remaining[0]
        )

    directory = os.path.dirname(os.path.abspath(args.plist))
    descriptor, temporary = tempfile.mkstemp(prefix=".iterm2.", dir=directory)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            plistlib.dump(sanitized, handle, fmt=plistlib.FMT_XML, sort_keys=False)
        os.replace(temporary, args.plist)
    except BaseException:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


if __name__ == "__main__":
    main()
