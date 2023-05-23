def getCurrentWorkspace() {
   return "${WORKSPACE.split('@')[0]}"
}

def checkExistReleaseChart() {
    def deployed = sh(returnStdout: true, script: "helm list |grep -E '^auth-helm' |wc -l")
    return deployed
}

def userApiIPAddress() {
    def ipaddr = sh(returnStdout: true, script: "kubectl get -o jsonpath='{.spec.clusterIP}' services postgres-service")
    return ipaddr
}

def getDockerTag() {
    def tag  = sh(returnStdout: true, script: "git rev-parse --short=10 HEAD").trim()
    return tag
}

def namespace = "default"

pipeline {
    environment {
        CURRENT_WORKING_DIR = getCurrentWorkspace()
        DOCKER_HUB_USER = "hoangdung99er"
        DOCKER_HUB_PASSWORD = "TamSoTam888"
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
                    sh "./changeTag.sh ${DOCKER_TAG} deployments/frontend-deployment.yaml deployments/frontend-deployment-updated.yaml"
                    sh "./changeTag.sh ${DOCKER_TAG} deployments/postgres-deployment.yaml deployments/postgres-deployment-updated.yaml"
                    sh "./changeTag.sh ${DOCKER_TAG} deployments/user-api-deployment.yaml deployments/user-api-deployment-updated.yaml"
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
        stage('Expose Docker Tag') {
            steps {
                sh "chmod +x exposeDockerTag.sh"
                sh "export TAG_IMAGE=${DOCKER_TAG}"
            }
        }
        stage('Deploying to K8S') {
            steps {
                dir("${CURRENT_WORKING_DIR}") {
                    script {
                        // DEPLOYED=checkExistReleaseChart()
                        // echo "DEPLOYED: ${DEPLOYED}"
                        // if (DEPLOYED == 0) {
                            sh "chmod +x changeHostName.sh"
                            sh "kubectl apply -f deployments/frontend-deployment-updated.yaml"
                            sh "kubectl apply -f deployments/postgres-deployment-updated.yaml"
                            POSTGRES_HOST=userApiIPAddress()
                            sh "./changeHostName.sh ${POSTGRES_HOST} deployments/env-configmap.yaml deployments/env-configmap-updated.yaml"

                            // sh 'keystring=$(echo "$POSTGRES_HOST") /opt/homebrew/Cellar/jenkins/yq/4.33.3/bin/yq e -i ".data.POSTGRES_HOST = strenv(keystring)" deployments/env-configmap.yaml'

                            sh "kubectl apply -f deployments/env-configmap-updated.yaml"
                            sh "kubectl apply -f deployments/env-secret.yaml"
                            sh "kubectl apply -f deployments/user-api-deployment-updated.yaml"
                            sh "kubectl apply -f deployments/ingress.yaml"

                            // sh "helm install -n ${namespace} auth-helm -f values.yaml ."
                    //     } else {
                    //         sh "helm --namespace=${namespace} upgrade -f values.yaml auth-helm ."
                    //     }
                    }
                    // sh "helm --namespace=$namespace upgrade -f values.yaml auth-helm ."
                }
                // dir("${CURRENT_WORKING_DIR}/postgres-helm") {
                    // sh 'yq e -i ".image.tag = env(TAG_IMAGE)" values.yaml'
                    // sh "helm --namespace=$namespace upgrade postgres-helm -f values.yaml postgres-helm"
                    // sh "helm install -n default postgres-helm -f values.yaml ."
                // }
                // dir("${CURRENT_WORKING_DIR}/user-api-helm") {
                //     sh 'yq e -i ".image.tag = env(TAG_IMAGE)" values.yaml'
                //     sh "helm --namespace=$namespace upgrade user-api-helm -f values.yaml user-api-helm"
                    // sh "helm install -n default user-api-helm -f values.yaml ."
                // }
            }
        }
    }
}
