#!/bin/sh

STATUS=`git status 2>&1`
if [ $? -eq 0 ]; then
  echo "Building version info from git"
  HASH=`git show --format=%H | head -1`
  TSTAMP=`git show --format=%at | head -1`
  echo "    * version -> $HASH"
  SYM=`git name-rev $HASH | awk '{print $2;}' | sed -e 's/\^.*//'`
  TAG=`git describe --tags --exact-match 2>/dev/null`
  if [ -n "$TAG" ]; then
    SYM="$TAG"
  elif [ -z "`echo $SYM | grep '^tags/'`" ]; then
    SYM="branches/$SYM"
  fi
  echo "    * symbolic -> $SYM"
  BRANCH=$SYM
  VERSION="$HASH.$TSTAMP"
  if [ -n "`echo $STATUS | grep 'Changed but not updated'`" ]; then
    VERSION="$HASH.modified.$TSTAMP"
  fi
else
  BRANCH=exported
  echo "    * exported"
fi

if [ -r "$1" ]; then
  eval `cat mtev_version.h | awk '/^#define/ { print $2"="$3;}'`
  if [ "$MTEV_BRANCH" = "$BRANCH" -a "$MTEV_VERSION" = "$VERSION" ]; then
    echo "    * version unchanged"
    exit
  fi
fi

cat > $1 <<EOF
#ifndef MTEV_VERSION_H
#ifndef MTEV_BRANCH
#define MTEV_BRANCH "$BRANCH"
#endif
#ifndef MTEV_VERSION
#define MTEV_VERSION "$VERSION"
#endif

#include <stdio.h>

static inline int mtev_build_version(char *buff, int len) {
  const char *start = MTEV_BRANCH;
  if(!strncmp(start, "branches/", 9)) 
    return snprintf(buff, len, "%s.%s", start+9, MTEV_VERSION);
  if(!strncmp(start, "tags/", 5)) 
    return snprintf(buff, len, "%s.%s", start+5, MTEV_VERSION);
  return snprintf(buff, len, "%s.%s", MTEV_BRANCH, MTEV_VERSION);
}

#endif
EOF
