pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'tahoordocker'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        VITE_API_URL   = 'http://3.236.208.161:4000'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build Images') {
            steps {
                sh 'docker build -t fda-backend:$IMAGE_TAG ./backend'
                sh 'docker build --build-arg VITE_API_URL=$VITE_API_URL -t fda-frontend:$IMAGE_TAG ./frontend'
                sh 'docker build --build-arg VITE_API_URL=$VITE_API_URL -t fda-admin:$IMAGE_TAG ./admin'
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
                                docker tag fda-${svc}:\$IMAGE_TAG \$DOCKERHUB_USER/fda-${svc}:\$IMAGE_TAG
                                docker tag fda-${svc}:\$IMAGE_TAG \$DOCKERHUB_USER/fda-${svc}:latest
                                docker push \$DOCKERHUB_USER/fda-${svc}:\$IMAGE_TAG
                                docker push \$DOCKERHUB_USER/fda-${svc}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Clean Local Images') {
            steps {
                script {
                    ['backend','frontend','admin'].each { svc ->
                        sh "docker rmi fda-${svc}:\$IMAGE_TAG || true"
                    }
                }
                sh 'docker image prune -f || true'
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([
                    string(credentialsId: 'jwt-secret',    variable: 'JWT_SECRET'),
                    string(credentialsId: 'stripe-secret', variable: 'STRIPE_SECRET_KEY')
                ]) {
                    sh '''
                        docker compose pull
                        docker compose up -d
                        docker compose ps
                    '''
                }
            }
        }
    }

    post {
        always  { sh 'docker logout || true' }
        failure { echo 'Pipeline failed - check the stage logs above.' }
    }
}
