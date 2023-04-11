pipeline {
    agent any
    stages{
        stage ('Git clone') {
            steps {
                git 'https://github.com/formycore/docker_maven_github_project.git'
            }
        }
        stage ('docker build'){
            steps {
                // sh 'docker build -t check:v1 .'
                sh "docker image build -t $JOB_NAME:v1.$BUILD_ID ."
                sh "docker image tag $JOB_NAME:v1.$BUILD_ID formycore/$JOB_NAME:v1.$BUILD_ID"
                sh "docker image tag $JOB_NAME:v1.$BUILD_ID formycore/$JOB_NAME:latest"
            }
        }
        stage ('Docker Push') {
            steps {
            withCredentials([usernamePassword(credentialsId: 'dockerid', passwordVariable: 'password', usernameVariable: 'username')]) {
                sh "docker login -u ${username} -p ${password}"
                sh "docker image push formycore/$JOB_NAME:v1.$BUILD_ID"
                sh "docker rmi $JOB_NAME:v1.$BUILD_ID formycore/$JOB_NAME:latest formycore/$JOB_NAME:v1.$BUILD_ID"
}
            }
        }
        stage('Docker Deployment'){
            steps {
                sh 'docker rm -f webserver'
                sh 'docker rmi -f formycore/dockerfile_maven_github_1'
                sh 'docker run -itd --name webserver -p 8090:8080 formycore/dockerfile_maven_github_1'
                
            }
        }
    }
}