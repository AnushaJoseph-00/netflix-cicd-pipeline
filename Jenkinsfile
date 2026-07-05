pipeline {
    agent any

    tools {
        nodejs 'node16'
    }

    environment {
        REACT_APP_TMDB_KEY   = credentials('Netflix-tmdb-api-key')
        SKIP_PREFLIGHT_CHECK = 'true'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/AnushaJoseph-00/netflix-cicd-pipeline.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Sonar Code Analysis') {
            environment {
                scannerHome = tool 'sonar-scanner'
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh '''${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=netflix-clone \
                        -Dsonar.projectName=netflix-clone \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.exclusions=node_modules/**,build/** \
                        -Dsonar.sourceEncoding=UTF-8'''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Upload to Nexus') {
            steps {
                sh "cd build && zip -r ../netflix-build-${BUILD_NUMBER}.zip . && cd .."
                withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                                  usernameVariable: 'NEXUS_USER',
                                  passwordVariable: 'NEXUS_PASS')]) {
                    sh "curl -f -u \$NEXUS_USER:\$NEXUS_PASS --upload-file netflix-build-${BUILD_NUMBER}.zip http://172.31.43.5:8081/repository/netflix-builds/netflix-build-${BUILD_NUMBER}.zip"
                }
            }
        }

        stage('Deploy to App Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                                  usernameVariable: 'NEXUS_USER',
                                  passwordVariable: 'NEXUS_PASS')]) {
                    sshagent(['app-server-ssh']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@172.31.33.101 \"curl -f -u \$NEXUS_USER:\$NEXUS_PASS -o /tmp/netflix-build.zip http://172.31.43.5:8081/repository/netflix-builds/netflix-build-${BUILD_NUMBER}.zip && sudo rm -rf /var/www/html/* && sudo unzip -o /tmp/netflix-build.zip -d /var/www/html/ && rm /tmp/netflix-build.zip\""
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded - build ${BUILD_NUMBER} deployed"
        }
        failure {
            echo "Pipeline failed - check the stage logs"
        }
        always {
            sh "rm -f netflix-build-*.zip"
        }
    }
}
