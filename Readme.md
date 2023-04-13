Using Multi-Stage Builds to Simplify And Standardize Build Processes

Introduction
One of the challenges facing Capital One DevOps engineers is providing a consistent build, run, and deployment environment for their developers. In my case, my developers support roughly 65 different websites, meaning that maintaining pipelines and build processes gets complicated quickly. To satisfy compliance, maintain code quality, and prevent issues, we’ve incorporated a variety of tools and tests in our builds; relying on CICD platforms to manage those tests and tools relies too heavily on external dependencies such as Jenkins plugin upgrades, binary upgrades on the CICD platform, and new releases of underlying software.

Imagine a normal pipeline for an application. It might look something like this:


Each of the stages — build, lint, test (unit, integration, accessibility, and regression), static code analysis, dynamic code analysis, and finally deployment — require access to different tools, systems, and binaries. Every time a developer runs a build or pushes to GitHub they could discover new issues in the pipeline and have to iterate to resolve them. This pushes information we want the developers to have to the right in the development process, which is suboptimal. There are two improvements that can be made to that process:

Shifting the information left — Whether it’s security, compliance, accessibility, code coverage, or linting, we want developers to have access to the results as early in the process as possible.
Standardizing the commands — This way no matter where the particular stage is run, the same results are returned.
Multi-stage Dockerfile builds solve both of these problems in an elegant way. Leveraging multi-stage Dockerfiles mean that a developer can run the exact same command as the CICD server, and because it’s running in a container, the same results should be returned every time.

What Are Multi-Stage Builds?
Multi-stage builds are a method of organizing a Dockerfile to minimize the size of the final container, improve run time performance, allow for better organization of Docker commands and files, and provide a standardized method of running build actions. A multi-stage build is done by creating different sections of a Dockerfile, each referencing a different base image. This allows a multi-stage build to fulfill a function previously filled by using multiple docker files, copying files between containers, or running different pipelines.

For more specific reading on the specifications of a multi-stage Docker build please see here. The Docker documentation provides a great introduction into multi-stage builds. However, an introduction isn’t a real world example. So let’s dive into one.

Writing A Multi-Stage Dockerfile
Now that we have an idea of what a multi-stage build is, and the problem it purports to solve, let’s try writing a Dockerfile for our example pipeline — covering build, lint, test, static code analysis, dynamic code analysis, and finally deployment.

Building
For this example, we’re going to put a Node application through our pipeline, and we’re going to use a multi-stage Dockerfile to do so. For that, we’re going to use a base Dockerfile that runs NPM install. Right now, all we are going to do is add a section header.

```
# Copies in our code and runs NPM Install
FROM node:latest as builder
WORKDIR /usr/src/app
COPY package* ./
COPY src/ src/
RUN [“npm”, “install”]
```
Linting
Perhaps we need to run a linter against a set of rules like the AirBnB set of ES6 rules. For this, we are going to copy from a previous stage — builder — to make sure that we don’t end up with modified or extra code. We only want code that is sourced from the initial copy in to be looked at. In the graphic I’ve used eslinter, though there are a variety of javascript linters available, an alternative would be jslint.

```
# Lints Code
FROM node:latest as linting
WORKDIR /usr/src/app
COPY — from=builder /usr/src/app/src .
RUN [“npm”, “lint”]
```
Static Analysis
Like a lot of applications for a lot of companies, you’ll probably use something for static code analysis. Here I’ve used SonarQube as an example because it’s open source, easy to use, and easy to set up. However, you could also write a Dockerfile scanner for any static analysis tool your company or application uses; a variety of alternatives to Sonarqube are listed here on Wikipedia.

```
# Gets Sonarqube Scanner from Dockerhub and runs it
FROM newtmitch/sonar-scanner:latest as sonarqube
COPY — from=builder /usr/src/app/src /root/src
```
Unit Testing
Hopefully you’re writing unit tests, right? And making sure that you’ve covered your business logic code with tests that show whether errors have happened, the data is validated, etc.? This is a simple, generalized example, but it makes sure that only the intended code is tested by copying from a previous testing stage. This helps guarantee a repeatable result. In the graphic/code I’ve used jest to represent unit testing, though there are a litany of testing frameworks. Examples include: JSUnit, Mocha, and Jasmine.

```
# Runs Unit Tests
FROM node:latest as unit-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN [“npm”, “test”]
```
Accessibility Tests
Similar to unit testing, we run whatever accessibility tests are desired. Hopefully you are doing those so that people who are color-blind, for example, can use your app/website. For more info on accessibility testing see this article. In the graphic and code I’ve used Pa11y to represent unit testing though there are both open and closed source alternatives like AATT by Paypal.

```
# Runs Accessibility Tests
FROM node:latest as access-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN [“npm”, “access-tests”]
```
Starting Application
Finally the actual application stage. For this stage we copy in the build files from the destination, and any package.json/package-lock.json files and then run npm start. However this would obviously be different if you were using some other language/method of running the application.

```
# Starts and Serves Web Page
FROM node:latest as serve
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/dest ./
COPY --from=builder /usr/src/app/package* ./
RUN [“npm”, “start”]
```
Now that we’ve written each individual stage the complete Dockerfile will look something like this:

# Copies in our code and runs NPM Install
FROM node:latest as builder
WORKDIR /usr/src/app
COPY package* ./
COPY src/ src/
RUN [“npm”, “install”]
# Lints Code
FROM node:latest as linting
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN [“npm”, “lint”]
# Gets Sonarqube Scanner from Dockerhub and runs it
FROM newmitch/sonar-scanner:latest as sonarqube
COPY --from=builder /usr/src/app/src /root/src
# Runs Unit Tests
FROM node:latest as unit-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN [“npm”, “test”]
# Runs Accessibility Tests
FROM node:latest as access-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN [“npm”, “access-tests”]
# Starts and Serves Web Page
FROM node:latest as serve
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/dest ./
COPY --from=builder /usr/src/app/package* ./
RUN [“npm”, “start”]
You’ll notice that in each of the sections, following the base image, is a name listed following: as This allows individual sections to be run by doing: docker build --target builder -t example-node:latest . And if you want to run your unit tests, you can run them by doing: docker build --target unit-tests -t example-node:latest . When the application needs to be built for running/deployment you can build it just like you would any other container with: docker build -t example-node:latest. This will produce the final application container in a small and deployable image.

This allows the developer to quickly see the same results locally that they’d get from waiting for the CICD server to return them. This also allows developers to be certain of what command is going to be run when a CICD server calls or builds a particular section.

Why Not to Use Multi-Stage Builds
There are a number of really good reasons to use multi-stage builds. A stage could be created to build differently per different environments or load different data into applications based on certain clients — the possibilities are endless. But multi-stage builds don’t always make sense.

While multi-stage builds provide consistency across build and run environments, there are challenges surrounding organizing build and run stages, increasing the physical size and logical organization of the Dockerfile, and the management of files copied between stages. Multi-stage builds may also not be correct for you if you are trying to keep Dockerfiles as simple as possible because your developers aren’t as used to it as their traditional tooling. It also requires a discussion around common hooks in your applications such that the build command, for example, will always produce a built artifact. None of these are necessarily unique to using multi-stage builds, but are things to keep in mind as you write your stages. These problems would normally be solved in a Jenkinsfile, or some other pipeline, as code. And while you’ve moved the stages and information left, you’ve also added some complexity in managing intermediary Docker containers, images, and dependencies.

Why to Use Multi-Stage Builds
Multi-stage builds allow you to separate build, test, and run time environments needing separate Dockerfiles. They allow you to minimize the actual size of the final Docker container that you deploy, because the various layers are no longer stored in the final container. This can cut your container down in half, or even by two-thirds depending on your stages and use case. It also allows you to ensure that there aren’t extra binaries in your deployed container, decreasing your attack vector. It can easily highlight inefficiencies in your build process and allow for unified optimization as only the Dockerfile/base image has to be updated. This can allow you to standardize your commands, preventing undue confusion, and moving the information left in the process of writing code.

Another added benefit of Multi-stage builds are the ability to run steps/stage in parallel. As your testing frameworks and repositories grow, integrations grow, and requirements change the ability to run all stages simultaneously and cut down on build times in whatever CICD tool is being used, or locally. Removing time barriers from developers getting information is a foundational part of DevOps and it’s goal of moving information left and multi-stage builds is a great representation of how to run things in in parallel and in self-contained stages to get developers what they need.

Multi-stage builds simplified a lot of my team’s CICD pipeline and provided an easy way for our developers to interact with the various expected gates on the way to a production deployment. This greatly improved consistency across our applications and presented a unified method of getting results for our developers and auditors.

