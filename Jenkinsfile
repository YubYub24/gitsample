pipeline {
    agent {
        label 'docker'
    }

    parameters {
        string(name: 'DOCKER_USERNAME', defaultValue: 'your-default-username', description: 'Docker Hub username (e.g. teamA)')
        string(name: 'IMAGE_NAME', defaultValue: 'sched_image', description: 'Docker image name')
    }

    environment {
        DOCKER_CREDS = credentials('docker-hub-creds') // used for login
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    def dockerUsername = params.DOCKER_USERNAME.trim()
                    def imageName = params.IMAGE_NAME.trim()
                    def imageTag = env.BUILD_NUMBER
                    def fullImage = "${dockerUsername}/${imageName}:${imageTag}"
                    def latestImage = "${dockerUsername}/${imageName}:latest"

                    echo "Building Docker image: ${fullImage}"

                    sh """
                        docker build \\
                        --network=host \\
                        -t ${fullImage} \\
                        -t ${latestImage} .
                    """

                    // Save image names for later stages
                    env.FULL_IMAGE = fullImage
                    env.LATEST_IMAGE = latestImage
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            docker push ${env.FULL_IMAGE}
                            docker push ${env.LATEST_IMAGE}
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def manifests = [
                        'k8s/deployment-canary.yaml',
                        'k8s/deployment-stable.yaml',
                        'k8s/service.yaml',
                        'k8s/pvc.yaml',
                        'k8s/namespace.yaml'
                    ]

                    for (manifest in manifests) {
                        sh """
                            sed "s|__DOCKER_IMAGE__|${env.FULL_IMAGE}|g" ${manifest} | kubectl apply -f -
                        """
                    }
                }
            }
        }
    }
}
