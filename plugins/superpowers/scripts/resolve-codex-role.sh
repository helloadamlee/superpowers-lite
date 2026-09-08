#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  printf 'ERROR: exactly one modelTier is required\n' >&2
  exit 2
fi

case "$1" in
  mechanical)
    printf '%s\n' superpowers_luna_implementer
    ;;
  standard)
    printf '%s\n' superpowers_terra_implementer
    ;;
  frontier)
    printf '%s\n' superpowers_astra_implementer
    ;;
  review)
    printf '%s\n' superpowers_astra_reviewer
    ;;
  *)
    printf 'ERROR: unknown modelTier: %s\n' "${1-}" >&2
    exit 2
    ;;
esac
