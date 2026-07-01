#!/bin/bash
curl -sLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz
tar -xf flutter_linux_3.29.0-stable.tar.xz
export PATH="$PWD/flutter/bin:$PATH"
git config --global --add safe.directory "*"
flutter --version