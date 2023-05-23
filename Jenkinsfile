def getCurrentWorkspace() {
   return "${WORKSPACE.split('@')[0]}"
}

def checkExistDeployment(svc) {
    def deployed = sh(returnStdout: true, script: "kubectl get deploy |grep -E '^${svc}' |wc -l")
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
        // stage("Dummy") {
        //     steps {
        //         DEPLOYMENT=checkExistDeployment("user-api")
        //         if(DEPLOYMENT == 1) {
        //             echo "1"
        //         } else {
        //             echo "2"
        //         }
        //         echo "DEPLOYMENT: $DEPLOYMENT"
        //     }
        // }
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
                        sh "chmod +x changeHostName.sh"
                        sh '''
                            FRONTEND_DEPLOY=frontend-deploy
                            FRONTEND_DEPLOYMENT=$(kubectl get deploy |grep -E "^${FRONTEND_DEPLOY}" |wc -l)
                            if [ $FRONTEND_DEPLOYMENT == 0 ]; then
                                kubectl apply -f deployments/frontend-deployment-updated.yaml
                            else
                                kubectl set image deployment/frontend-deploy frontend=${DOCKER_HUB_USER}/frontend:${DOCKER_TAG}
                            fi
                            echo "FRONTEND SERVICE DEPLOYED"

                            POSTGRES_DEPLOY=postgres-deploy
                            POSTGRES_DEPLOYMENT=$(kubectl get deploy |grep -E "^${POSTGRES_DEPLOY}" |wc -l)
                            if [ $POSTGRES_DEPLOYMENT == 0 ]; then
                                kubectl apply -f deployments/postgres-deployment-updated.yaml
                            else
                                kubectl delete deploy ${POSTGRES_DEPLOY}
                                kubectl apply -f deployments/postgres-deployment-updated.yaml
                            fi
                            echo "POSTGRES SERVICE DEPLOYED"

                            POSTGRES_HOST=$(kubectl get -o jsonpath='{.spec.clusterIP}' services postgres-service)
                            ./changeHostName.sh ${POSTGRES_HOST} deployments/env-configmap.yaml deployments/env-configmap-updated.yaml

                            kubectl apply -f deployments/env-configmap-updated.yaml
                            echo "ENVIRONMENT CONFIMAP DEPLOYED"

                            kubectl apply -f deployments/env-secret.yaml
                            echo "ENVIRONMENT SECRET DEPLOYED"

                            USER_API=user-api
                            DEPLOYMENT=$(kubectl get deploy |grep -E "^${USER_API}" |wc -l)
                            if [ $DEPLOYMENT == 0 ]; then
                                kubectl apply -f deployments/user-api-deployment-updated.yaml
                            else
                                kubectl delete deploy ${USER_API}
                                kubectl apply -f deployments/user-api-deployment-updated.yaml
                            fi
                            echo "USER SERVICE DEPLOYED"
                        '''
                        // sh "kubectl apply -f deployments/frontend-deployment-updated.yaml"
                        // sh "kubectl apply -f deployments/postgres-deployment-updated.yaml"

                        // sh "kubectl apply -f deployments/env-configmap-updated.yaml"
                        // sh "kubectl apply -f deployments/env-secret.yaml"
                        // sh "kubectl apply -f deployments/user-api-deployment-updated.yaml"
                        // sh "kubectl apply -f deployments/ingress.yaml"

                        echo "APPLICATION DEPLOYED"
                    }
                }
            }
        }
    }
}
