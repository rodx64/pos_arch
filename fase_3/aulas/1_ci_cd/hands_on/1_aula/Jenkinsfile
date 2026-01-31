pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:20-alpine
    command:
    - cat
    tty: true
"""
        }
    }
    
    environment {
        APP_NAME = 'fiap-cicd-demo'
        NODE_VERSION = '20'
    }
    
    stages {
        stage('📥 Checkout') {
            steps {
                echo '📥 Fazendo checkout do código...'
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('🔍 Environment Info') {
            parallel {
                stage('Node Info') {
                    steps {
                        container('node') {
                            echo '🟢 Verificando ambiente Node.js...'
                            sh '''
                                echo "Node version: $(node --version)"
                                echo "NPM version: $(npm --version)"
                                echo "Current directory: $(pwd)"
                            '''
                        }
                    }
                }
                stage('System Info') {
                    steps {
                        echo '🖥️ Informações do sistema:'
                        sh '''
                            echo "OS: $(uname -a)"
                            echo "Date: $(date)"
                            echo "User: $(whoami)"
                        '''
                    }
                }
            }
        }
        
        stage('📦 Dependencies') {
            steps {
                container('node') {
                    dir('app') {
                        echo '📦 Instalando dependências...'
                        sh '''
                            npm ci
                            echo "✅ Dependências instaladas com sucesso!"
                        '''
                    }
                }
            }
        }
        
        stage('🧪 Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        container('node') {
                            dir('app') {
                                echo '🧪 Executando testes unitários...'
                                sh '''
                                    npm test
                                    echo "✅ Testes unitários concluídos!"
                                '''
                            }
                        }
                    }
                }
                stage('Coverage') {
                    steps {
                        container('node') {
                            dir('app') {
                                echo '📊 Gerando relatório de cobertura...'
                                sh '''
                                    npm run test:coverage
                                    echo "✅ Relatório de cobertura gerado!"
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('🔒 Security') {
            steps {
                container('node') {
                    dir('app') {
                        echo '🔒 Executando auditoria de segurança...'
                        sh '''
                            npm audit --audit-level=moderate || true
                            echo "✅ Auditoria de segurança concluída!"
                        '''
                    }
                }
            }
        }
        
        stage('🏗️ Build') {
            steps {
                container('node') {
                    dir('app') {
                        echo '🏗️ Fazendo build da aplicação...'
                        sh '''
                            echo "Building application..."
                            # Aqui seria o build real (webpack, etc)
                            echo "✅ Build concluído com sucesso!"
                        '''
                    }
                }
            }
        }
        
        stage('🚀 Smoke Test') {
            steps {
                container('node') {
                    dir('app') {
                        echo '🚀 Executando smoke test...'
                        sh '''
                            # Instalar curl (Alpine Linux)
                            apk add --no-cache curl
                            
                            # Iniciar aplicação em background
                            npm start &
                            APP_PID=$!
                            
                            # Aguardar aplicação iniciar
                            sleep 10
                            
                            # Testar endpoints da API
                            curl -f http://localhost:3000/health || exit 1
                            curl -f http://localhost:3000/api/todos || exit 1
                            curl -f http://localhost:3000/api/stats || exit 1
                            
                            # Parar aplicação
                            kill $APP_PID
                            
                            echo "✅ Smoke test passou!"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Limpando workspace...'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline executado com sucesso!'
        }
        failure {
            echo '❌ Pipeline falhou!'
        }
    }
}
