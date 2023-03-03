#!/usr/bin/env bash
IMAGE_NAME=chillnet/laravel-crm
APP_NAME=laravel-crm
GIT_HASH=`git rev-parse --short HEAD`
GIT_DESCRIBED=`git describe --tags | sed 's/[\-\s]//'`
echo "Latest tag: ${GIT_DESCRIBED}"

@confirm() {
    local message="$*"
    local result=3

    echo -n "> $message (y/n) " >&2

    while [[ $result -gt 1 ]] ; do
        read -s -n 1 choice
        case "${choice}" in
        y|yes|j|ja|s|si|o|oui ) result=0 ;;
        n|N ) result=1 ;;
        esac
    done

    return $result
}

@printLine() {
    echo $(for i in $(seq 1 100); do printf "-"; done)
}

if @confirm 'Did you remember to tag your commit with [git tag -a] ?' ; then
    echo "Yes"
    @printLine
    echo "Lets build and tag your new image..."
    @printLine
    if [[ $(sysctl -n machdep.cpu.brand_string) =~ "Apple" ]]; then
        echo "Apple Silicone Detected!"
        if @confirm "Would you like to build the image for linux/arm64 (Apple Sillicon M1) ?" ; then
            echo "$(whoami) started to build a new docker image for: ${IMAGE_NAME}:${GIT_DESCRIBED} for linux/arm64 architecture"

            docker build --label "com.repo.git.hash=${GIT_HASH}" --build-arg SPATIE_MEDIA_LIBRARY_PRO_USERNAME=${SPATIE_MEDIA_LIBRARY_PRO_USERNAME} --build-arg SPATIE_MEDIA_LIBRARY_PRO_PASSWORD=${SPATIE_MEDIA_LIBRARY_PRO_PASSWORD} -t ${APP_NAME}:latest .

            MSG="done with building the image with label com.repo.git.hash=${GIT_HASH}"
            echo ${MSG}
            echo ${MSG}
            @printLine
            echo "${APP_NAME}:latest build successfully"
        fi
    else
        echo "$(whoami) started to build a new docker image for: ${IMAGE_NAME}:${GIT_DESCRIBED}"
        docker build --label "com.repo.git.hash=${GIT_HASH}" --build-arg SPATIE_MEDIA_LIBRARY_PRO_USERNAME=${SPATIE_MEDIA_LIBRARY_PRO_USERNAME} --build-arg SPATIE_MEDIA_LIBRARY_PRO_PASSWORD=${SPATIE_MEDIA_LIBRARY_PRO_PASSWORD} -t ${APP_NAME} -t ${APP_NAME}:latest .
        MSG="done with building the image with label com.repo.git.hash=${GIT_HASH}"
        echo ${MSG}
        echo ${MSG}
        @printLine
        echo "Now lets tag the image..."
        docker tag ${APP_NAME} ${IMAGE_NAME}:${GIT_DESCRIBED}
        docker tag ${APP_NAME} ${IMAGE_NAME}:latest
        echo "done!"
        echo "${IMAGE_NAME}:${GIT_DESCRIBED} build successfully"
    fi
    echo;
    @printLine
else
    echo "No"
    @printLine;
    echo "Please do that first!"
    echo "by running: [git commit] and then: [git tag -a ${GIT_DESCRIBED%?}x] where x represents your build number. "
    echo "When you are done with that, you can manually build and tag the new docker image with: "
    @printLine;
    echo docker build --label "com.repo.git.hash=${GIT_HASH}" --build-arg SPATIE_MEDIA_LIBRARY_PRO_USERNAME=${SPATIE_MEDIA_LIBRARY_PRO_USERNAME} --build-arg SPATIE_MEDIA_LIBRARY_PRO_PASSWORD=${SPATIE_MEDIA_LIBRARY_PRO_PASSWORD} -t ${APP_NAME} .
    echo "Using Apple Silicone M1"
    echo docker buildx build --platform linux/amd64,linux/arm64  --build-arg SPATIE_MEDIA_LIBRARY_PRO_USERNAME=${SPATIE_MEDIA_LIBRARY_PRO_USERNAME} --build-arg SPATIE_MEDIA_LIBRARY_PRO_PASSWORD=${SPATIE_MEDIA_LIBRARY_PRO_PASSWORD} --push --label "com.repo.git.hash=${GIT_HASH}" -t ${APP_NAME} .
    echo docker tag ${APP_NAME} ${IMAGE_NAME}:${GIT_DESCRIBED}
    echo docker tag ${APP_NAME} ${IMAGE_NAME}:latest
    @printLine;
    exit 1;
fi

if @confirm "Would you like to push ${IMAGE_NAME}:${GIT_DESCRIBED} to dockerhub ?" ; then
    echo;
    echo "Starting to build a linux/amd64 based image on Apple Sillicon and pushing the new build ${IMAGE_NAME}:${GIT_DESCRIBED} to dockerhub"
    if [[ $(sysctl -n machdep.cpu.brand_string) =~ "Apple" ]]; then
        echo "Apple Silicone Detected Building linux/amd64,linux/arm64 and pushing to dockerhub"
        @printLine
        docker login
        @printLine
        docker buildx build --push --platform linux/amd64,linux/arm64  --label "com.repo.git.hash=${GIT_HASH}"  --build-arg SPATIE_MEDIA_LIBRARY_PRO_USERNAME=$SPATIE_MEDIA_LIBRARY_PRO_USERNAME --build-arg SPATIE_MEDIA_LIBRARY_PRO_PASSWORD=$SPATIE_MEDIA_LIBRARY_PRO_PASSWORD -t ${IMAGE_NAME}:${GIT_DESCRIBED} -t ${IMAGE_NAME}:latest .
        @printLine
    else
        docker push ${IMAGE_NAME}:${GIT_DESCRIBED}
    fi
    echo "${IMAGE_NAME}:${GIT_DESCRIBED} successfully uploaded to dockerhub"
else
    echo "No"
    @printLine
    echo "Remember to do it manually then..."
    @printLine
    echo docker push ${IMAGE_NAME}:${GIT_DESCRIBED}
    @printLine
fi

echo "Remember to run: sed -e 's/APP_VERSION=.*/APP_VERSION=${GIT_DESCRIBED}/' .env | pbcopy && pbpaste > .env"
echo
