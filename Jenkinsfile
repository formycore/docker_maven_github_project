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
                sh 'docker build -t check:v1 .'
            }
        }
    }
}