FROM alpine/git as clone
ARG url
WORKDIR /app
RUN git clone ${url}

FROM maven:3.5-jdk-11-slim as build
ARG project
WORKDIR /app
COPY --from=clone /app/${project} /app/
RUN mvn install

# /webapp/target/webapp.war
From tomcat:8-jre8
ARG artifact
COPY --from=build /app/webapp/target/${artifact}.war /usr/local/tomcat/webapps/
EXPOSE 8080
## Check the notes to run this Dockerfile

