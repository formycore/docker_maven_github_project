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
                sh 'docker image build -t $JOB_NAME:v1.$BUILD_ID .'
            }
        }
        stage ('Docker Push') {
            steps {
            withCredentials([usernamePassword(credentialsId: 'dockerid', passwordVariable: 'password', usernameVariable: 'username')]) {
                sh "docker login -u ${username} -p ${password}"
                sh "docker image push formycore/$JOB_NAME:v1.$BUILD_ID"
}
            }
        }
    }
}