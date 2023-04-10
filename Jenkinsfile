pipeline {
    agent any
    stages{
        stage ('Git clone') {
            steps {
                git 'https://github.com/ravdy/hello-world.git'
            }
        }
        stage ('docker build'){
            sh 'docker build -t check:v1 .'
        }
    }
}