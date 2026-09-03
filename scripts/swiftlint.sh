#!/bin/sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if which swiftlint >/dev/null 2>&1; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
