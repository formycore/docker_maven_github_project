FROM alpine/git as clone
WORKDIR /app
RUN git clone https://github.com/formycore/docker_pipeline_valaxy.git

FROM maven:3.5-jdk-11-slim as build
WORKDIR /app
COPY --from=clone /app/docker_pipeline_valaxy /app/
RUN mvn install

# /webapp/target/webapp.war
From tomcat:8-jre8
COPY --from=build /app/webapp/target/webapp.war /usr/local/tomcat/webapps/
EXPOSE 8080

