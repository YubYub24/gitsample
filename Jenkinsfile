pipeline {
    agent {
        label "docker"
    }

    environment {
        // Securely pull Docker Hub credentials
        DOCKER_CREDS = credentials('docker-hub-creds')
        IMAGE_NAME = "sched_image"
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${DOCKER_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE = "${DOCKER_CREDS_USR}/${IMAGE_NAME}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    sh """
                        docker build \\
                        --network=host \\
                        -t ${FULL_IMAGE} \\
                        -t ${LATEST_IMAGE} .
                    """
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    sh "docker push ${LATEST_IMAGE}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/pvc.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl apply -f k8s/deployment-canary.yaml
                        kubectl apply -f k8s/deployment-stable.yaml
                    """
                }
            }
        }
    }
}
