def getCurrentWorkspace() {
   return "${WORKSPACE.split('@')[0]}"
}

def getDockerTag(){
    def tag  = sh(returnStdout: true, script: "git rev-parse --short=10 HEAD").trim()
    return tag
}

def namespace = "default"

pipeline {
    environment {
        CURRENT_WORKING_DIR = getCurrentWorkspace()
        DOCKER_HUB_USER = credentials("docker-hub-user")
        DOCKER_HUB_PASSWORD = credentials("docker-hub-password")
        DOCKER_TAG = getDockerTag()
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
                    sh "docker compose -f docker-compose-build-custom-tag.yaml build --parallel"
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
            parallel {
                stage('Expose Docker Tag') {
                    steps {
                        sh "chmod +x exposeDockerTag.sh ${DOCKER_TAG}"
                        sh './exposeDockerTag.sh'
                    }
                }
                stage('Deploying to K8S') {
                    steps {
                        dir("${CURRENT_WORKING_DIR}/auth-helm") {
                            sh 'yq e -i ".image.tag = env(TAG_IMAGE)" values.yaml'
                            sh "helm --namespace=$namespace upgrade auth-helm -f values.yaml auth-helm"
                        }
                        dir("${CURRENT_WORKING_DIR}/postgres-helm") {
                            sh 'yq e -i ".image.tag = env(TAG_IMAGE)" values.yaml'
                            sh "helm --namespace=$namespace upgrade postgres-helm -f values.yaml postgres-helm"
                        }
                        dir("${CURRENT_WORKING_DIR}/user-api-helm") {
                            sh 'yq e -i ".image.tag = env(TAG_IMAGE)" values.yaml'
                            sh "helm --namespace=$namespace upgrade user-api-helm -f values.yaml user-api-helm"
                        }
                    }
                }
            }
        }
    }
}