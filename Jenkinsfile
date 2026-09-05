pipeline {
    agent any
    environment {
        DOCKERHUB_USER = 'tahoordocker'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        VITE_API_URL   = 'http://localhost:4000'
    }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build Images') {
            steps {
                sh 'docker build -t fda-backend:$IMAGE_TAG ./backend'
                sh 'docker build --build-arg VITE_API_URL=$VITE_API_URL -t fda-frontend:$IMAGE_TAG ./frontend'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
                    script {
                        ['backend','frontend'].each { svc ->
                            sh """
                                docker tag fda-${svc}:\$IMAGE_TAG \$DOCKERHUB_USER/fda-${svc}:\$IMAGE_TAG
                                docker push \$DOCKERHUB_USER/fda-${svc}:\$IMAGE_TAG
                            """
                        }
                    }
                }
            }
        }
        stage('Clean Local Images') {
            steps {
                script {
                    ['backend','frontend'].each { svc ->
                        sh "docker rmi fda-${svc}:\$IMAGE_TAG || true"
                        sh "docker rmi \$DOCKERHUB_USER/fda-${svc}:\$IMAGE_TAG || true"
                    }
                }
                sh 'docker image prune -f || true'
            }
        }
    }
    post {
        always  { sh 'docker logout || true' }
        success { echo "Pushed :${IMAGE_TAG}. Image Updater takes over." }
        failure { echo 'Pipeline failed - check stage logs.' }
    }
}
