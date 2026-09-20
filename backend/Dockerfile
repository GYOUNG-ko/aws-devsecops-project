FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY backend/pom.xml backend/pom.xml
RUN mvn -f backend/pom.xml -q -DskipTests dependency:go-offline
COPY backend backend
RUN mvn -f backend/pom.xml -q package

FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/pms
RUN addgroup -S pms && adduser -S -G pms -u 10001 pms \
    && mkdir -p /opt/pms/data \
    && chown -R pms:pms /opt/pms
COPY --from=build /workspace/backend/target/pms-backend-0.0.1-SNAPSHOT.jar app.jar
COPY app /opt/pms/app
ENV PMS_WEB_STATIC_LOCATION=/opt/pms/app/
EXPOSE 8080
USER 10001
ENTRYPOINT ["java", "-jar", "/opt/pms/app.jar"]
