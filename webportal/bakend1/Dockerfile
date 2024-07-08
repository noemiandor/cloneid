# syntax=docker/dockerfile:experimental
#FROM arm64v8/eclipse-temurin:17-jdk-alpine as build
FROM arm64v8/eclipse-temurin as builder
#FROM amd64/eclipse-temurin as builder
WORKDIR application
ARG JAR_FILE=target/*.jar
ARG JAR_FILE=build/libs/api-backend-0.0.1-SNAPSHOT.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract


FROM arm64v8/eclipse-temurin
#FROM amd64/eclipse-temurin
WORKDIR application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./

EXPOSE 8080

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

