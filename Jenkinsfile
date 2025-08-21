pipeline {
    agent {
        label "docker"
    }

    parameters {
        string(name: 'DOCKER_USERNAME', defaultValue: '', description: 'Docker Hub username (e.g. teamA)')
        string(name: 'IMAGE_NAME', defaultValue: 'sched_image', description: 'Docker image name')
    }

    environment {
        DOCKER_CREDS = credentials('docker-hub-creds') // still used for login
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${params.DOCKER_USERNAME}/${params.IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE = "${params.DOCKER_USERNAME}/${params.IMAGE_NAME}:latest"
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
                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${params.DOCKER_USERNAME} --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    sh "docker push ${LATEST_IMAGE}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Replace image placeholder in manifests and apply
                    def manifests = [
                        'k8s/deployment-canary.yaml',
                        'k8s/deployment-stable.yaml',
                        'k8s/service.yaml',
                        'k8s/pvc.yaml',
                        'k8s/namespace.yaml'
                    ]

                    for (manifest in manifests) {
                        sh """
                            sed 's|__DOCKER_IMAGE__|${FULL_IMAGE}|g' ${manifest} | kubectl apply -f -
                        """
                    }
                }
            }
        }
    }
}
