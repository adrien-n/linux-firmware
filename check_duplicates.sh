#!/bin/sh

# Check for duplicates across the current directory.
#
# If you have jdupes, use it (it's very small and not Java despite the 'j').
# Display duplicates:
#   jdupes -S -r --ext-filter=nostr:.git/ .
# Symlink duplicates:
#   jdupes -l -r --ext-filter=nostr:.git/ .

set -u

# Prefer xxh128sum over md5sum because it's much faster and many people are
# trying to make everything related to MD5 disappear.
if xxh128sum --version >/dev/null 2>/dev/null; then
  HASHER='xxh128sum'
else
  HASHER='md5sum'
fi

# Look for files, not in .git/, stat them, filter out the ones with a unique
# size, checksum the others, filter out the ones with a unique checksum, make
# the others into groups separated by empty lines, prettify the output, and
# provide a total count of duplicates.
find . \
  \( -name .git -type d -prune \) \
  -o \( -type f \! -name '*' \) \
  -exec stat --format='%n %s' {} + \
  | sort -s -k2n \
  | uniq --skip-fields=1 -D \
  | cut -f1 -d' ' \
  | xargs "${HASHER}" \
  | sort -k1 -s \
  | uniq --check-chars=40 -D \
  | uniq --check-chars=40 --group=prepend \
  | awk -F' ' '{print $2}' \
  | sed 's/^$/\nDuplicates:/' \
  | awk -F' ' 'BEGIN { duplicates = 0 } /\./ { print $0; duplicates++ } // { print $0 } END { if (duplicates > 0) { print ""}; printf("Duplicates count: %d\n", duplicates); if (duplicates > 0) { exit(200) } }'

ret="$?"

if [ "${ret}" -eq 200 ]; then
  cat <<EOF

************************************************************************
Duplicated files found.

Please get a list of duplicates with:
  jdupes -S -r --ext-filter=nostr:.git/ .

You can then optimize them with:
  jdupes -l -r --ext-filter=nostr:.git/ .

You can also change them by hand in order to control better which files
are kept as such and which files become symlinks to them.
************************************************************************
EOF
  exit 1
fi

if [ "${ret}" -ne 0 ]; then
  echo "An unknown error has occured." >&2
  exit "${ret}"
fi
