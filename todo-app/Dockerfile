# build using "docker build ./ -t $ARTIFACT_NAME --build-arg VERSION=1.2.3.4"
FROM mcr.microsoft.com/openjdk/jdk:17-mariner as runtime

ENV BUILD_VERSION=${VERSION_ARG}
ENV ARTIFACT_NAME=${ARTIFACT_NAME_ARG}
ENV PORT=80

WORKDIR /

ADD ./${ARTIFACT_NAME_ARG}-${VERSION_ARG}.jar /${ARTIFACT_NAME_ARG}-${VERSION_ARG}.jar
# ADD ./ai.jar /ai.jar

EXPOSE 80 443

# This application is using embeded AI.jar library for AppInsights, so it does not need to be injected into the docker file
# ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-javaagent:/ai.jar","-jar","/${ARTIFACT_NAME_ARG}-${VERSION_ARG}.jar"]
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/${ARTIFACT_NAME_ARG}-${VERSION_ARG}.jar"]