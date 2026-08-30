pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'tahoordocker'
        AWS_ACCOUNT    = '654654477638.dkr.ecr.us-east-1.amazonaws.com'
        AWS_REGION     = 'us-east-1'
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Images') {
            steps {
                sh 'docker build -t fda-backend:$IMAGE_TAG ./backend'
                sh 'docker build -t fda-frontend:$IMAGE_TAG ./frontend'
                sh 'docker build -t fda-admin:$IMAGE_TAG ./admin'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
                    script {
                        ['backend','frontend','admin'].each { svc ->
                            sh """
                                docker tag fda-${svc}:$IMAGE_TAG $DOCKERHUB_USER/fda-${svc}:$IMAGE_TAG
                                docker tag fda-${svc}:$IMAGE_TAG $DOCKERHUB_USER/fda-${svc}:latest
                                docker push $DOCKERHUB_USER/fda-${svc}:$IMAGE_TAG
                                docker push $DOCKERHUB_USER/fda-${svc}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $AWS_ACCOUNT
                    '''
                    script {
                        ['backend','frontend','admin'].each { svc ->
                            sh """
                                docker tag fda-${svc}:$IMAGE_TAG $AWS_ACCOUNT/fda-${svc}:$IMAGE_TAG
                                docker tag fda-${svc}:$IMAGE_TAG $AWS_ACCOUNT/fda-${svc}:latest
                                docker push $AWS_ACCOUNT/fda-${svc}:$IMAGE_TAG
                                docker push $AWS_ACCOUNT/fda-${svc}:latest
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'docker image prune -f || true'
        }
    }
}
