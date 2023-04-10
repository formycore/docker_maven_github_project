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
        stage ('docker run'){
            steps {
                sh 'docker rm -f $(docker ps -a -q)'
                sh 'docker run -it -d 8090:8080 check:v1'
            }
        }
    }
}