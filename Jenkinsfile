def getCurrentWorkspace() {
   return "${WORKSPACE.split('@')[0]}"
}

def getDockerTag(){
    def tag  = sh script: 'git rev-parse HEAD', returnStdout: true
    return tag
}

def namespace = "default"

pipeline {
    environment {
        CURRENT_WORKING_DIR = getCurrentWorkspace()
        DOCKER_HUB_USER = credentials("docker-hub-user")
        DOCKER_HUB_PASSWORD = credentials("docker-hub-password")
        DOCKER_TAG = "v1.0.10"
    }

    agent any
    options {
        skipDefaultCheckout(true)
    }

    stages {
        stage('Clean up') {
            steps {
                cleanWs()
                sh """
                echo "Cleaned up Workspace for Project"
                """
            }
        }
        stage("Checkout") {
            steps {
                script {
                    checkout scm
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                dir("${CURRENT_WORKING_DIR}") {
                    sh "chmod +x changeTag.sh docker-push-image.sh"
                    sh "./changeTag.sh ${DOCKER_TAG} docker-compose-build.yaml docker-compose-build-custom-tag.yaml"
                    sh "docker-compose -f docker-compose-build-custom-tag.yaml build --parallel"
                }
            }
        }
        stage("Push Image") {
            steps {
                sh 'docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}'
                sh "./docker-push-image.sh ${DOCKER_TAG}"
            }
        }
        stage("Apply K8S") {
            steps {
                dir("${CURRENT_WORKING_DIR}/auth-helm") {
                    echo "Deploying to K8S"
                    sh 'yq e -i ".image.tag = ${DOCKER_TAG}" auth-helm/values.yaml'
                    sh 'yq e -i ".image.tag = ${DOCKER_TAG}" postgres-helm/values.yaml'
                    sh 'yq e -i ".image.tag = ${DOCKER_TAG}" user-api-helm/values.yaml'
                    sh "helm --namespace=$namespace upgrade auth-helm -f ./values.yaml auth-helm"
                    sh "helm --namespace=$namespace upgrade postgres-helm -f ./values.yaml postgres-helm"
                    sh "helm --namespace=$namespace upgrade user-api-helm -f ./values.yaml user-api-helm"
                }
            }
        }
    }
}