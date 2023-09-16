FROM openjdk:11-slim-buster

WORKDIR /app

ARG ORIGINAL_JAR_FILE=./build/libs/config-service-1.0.0.jar

COPY ${ORIGINAL_JAR_FILE} config-service.jar

CMD ["java", "-jar", "/app/config-service.jar"]
