#!/usr/bin/env bash

function get_git_root() {
  git rev-parse --show-toplevel
}

function get_expected_ip() {
  local root
  root="$(get_git_root)"
  cat "${root}/config/latencylab-ip.txt"
}
