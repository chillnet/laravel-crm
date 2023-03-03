#!/usr/bin/env bash

function printLine()
{
    if [ -z $1 ]; then CHAR="="; else CHAR=$1; fi
	printf %100s |tr " " "$CHAR"
	echo
}

if [ -z $1 ]; then
    # get the most recent annotated tag:
    LATEST_TAG=$(git describe --abbrev=0)
    echo -e "\nMissing Tag!"
    echo -e "\nusage:\t$0 <git tag>"
    echo -e "\nWill use the latest tag $LATEST_TAG!\n"
else
    LATEST_TAG=$1
fi

SUFFIX=""

BRANCH=$(git rev-parse --abbrev-ref HEAD | grep release)
#Check if we are on a release branch, if so add beta SUFFIX
if [ "$BRANCH" ]; then
    printLine;
    echo "* release branch: $BRANCH";
    SUFFIX=$SUFFIX-beta
fi

printLine;
echo -e "Release Notes: "
printLine
echo -n '- '
git rev-list $LATEST_TAG...| xargs -n 1 git log --oneline --format=%B -n 1 | grep -v Merge | grep -v Approve | awk -v RS= -v ORS='\n- ' '1' | uniq | sed '$ d'
printLine
DB_SEED_CMD=`git log --reverse --format="" --name-only  $LATEST_TAG... | grep seeders | awk -F '/' '{ print $3}' | grep -v "DatabaseSeeder.php" | cut -d '.' -f 1 | sort | uniq`

if [ ! -z "$DB_SEED_CMD" ]; then
    echo -e "Remember to run DB Seed(s):"
    printLine '-';
    for i in $DB_SEED_CMD; do
        echo -e "php artisan db:seed --class=$i"
    done;
    printLine '-';
fi

echo;
printLine;
echo -e "Tag:\t\t\t\t$LATEST_TAG"
COMMIT_COUNT=$(git rev-list --count $LATEST_TAG...)
BUILD_NO=$(echo $LATEST_TAG | cut -d '.' -f 3 | sed 's/[^0-9]*//g' || echo 'unknown')
BUILD_NO=$(expr $BUILD_NO + 0)
test -z $BUILD_NO && BUILD_NO=$(echo $LATEST_TAG | cut -d '-' -f 2 | sed 's/[^0-9]*//g')
test -z $BUILD_NO && BUILD_NO=0
PREFIX=$(echo $LATEST_TAG | sed 's/-/./g' | cut -d '.' -f 1-2)
NEW_TAG=$(($COMMIT_COUNT+$BUILD_NO))
echo -e "Commits since $LATEST_TAG:\t\t$COMMIT_COUNT"
echo -e "Build number:\t\t\t$BUILD_NO"
NEW_VERSION="${PREFIX}.$(printf "%03d" ${NEW_TAG})${SUFFIX}"
echo -e "New build number:\t\t${NEW_VERSION}"
printLine '-';
echo -e "git tag -a ${NEW_VERSION}"
printLine;

echo;
