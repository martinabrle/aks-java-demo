FROM eclipse-temurin:17 as builder
WORKDIR application
ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME}.jar application.jar



# build using "docker build ./ -t tiny-java --build-arg VERSION=1.2.3.4"
# run using docker run -p 8080:8080 docker.io/library/tiny-java -e SPRING_PROFILES_ACTIVE=local
###############################################################################################
# build stage
# - using JDK image optimized by Java on Azure team
FROM mcr.microsoft.com/openjdk/jdk:17-ubuntu as build

VOLUME /tmp
WORKDIR /
ARG ARTIFACT_NAME

COPY .mvn .mvn
COPY mvnw .
COPY pom.xml .

ENV SPRING_PROFILES_ACTIVE=local
ENV JAVA_OPTS=-Dspring.profiles.active=local
ENV PORT=80

COPY src src

RUN apt-get update && apt-get install -y wget
RUN wget -q -O ai.jar https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.4.12/applicationinsights-agent-3.4.12.jar

RUN ./mvnw -B package
RUN mv ./target/${ARTIFACT_NAME}-*.jar "./target/appplication.jar"

# package stage
# For production, consider distroless image:
# FROM mcr.microsoft.com/openjdk/jdk:17-distroless as runtime
FROM mcr.microsoft.com/openjdk/jdk:17-mariner as runtime

ARG VERSION_ARG
ENV VERSION=$VERSION_ARG

WORKDIR /

COPY --from=build ./target/application.jar /application.jar
COPY --from=build ./ai.jar /ai.jar

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-javaagent:/ai.jar","-jar","/application.jar"]

#The distroless images are based on the CBL-Mariner 2.0 distribution by Microsoft.
#The ENTRYPOINT of these images is already configured pointing to the java command.
#Consuming Dockerfiles must use the CMD instruction to complete the command-line arguments of the JVM launcher process.
#CMD ["-jar", "/application.jar"]