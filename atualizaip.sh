#!/bin/bash

# Define o caminho completo para o Dockerfile
DOCKERFILE_PATH="/home/ec2-user/bia/Dockerfile"

echo "Iniciando o script para atualizar o IP no Dockerfile..."

# 1. Obter o IP público da máquina
echo "Obtendo o IP público da sua máquina..."
# Tenta obter o IP público usando ifconfig.me. Se falhar, tenta ipinfo.io.
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

# Verifica se o IP foi obtido com sucesso
if [ -z "$PUBLIC_IP" ]; then
  echo "Erro: Não foi possível obter o IP público. Verifique sua conexão com a internet ou o serviço de IP."
  exit 1
fi

echo "IP Público obtido: $PUBLIC_IP"

# 2. Verificar se o Dockerfile existe
if [ ! -f "$DOCKERFILE_PATH" ]; then
  echo "Erro: Dockerfile não encontrado em $DOCKERFILE_PATH."
  echo "Por favor, verifique o caminho e tente novamente."
  exit 1
fi

# 3. Alterar a linha no Dockerfile
# Usamos 'sed' para substituir a URL.
# O delimitador '#' é usado no sed para evitar conflitos com as barras '/' na URL.
# A expressão regular busca a linha que começa com "RUN cd client && VITE_API_URL="
# e captura o que vem depois de "http://" até o próximo caractere que não seja parte de um IP/porta.
# Em seguida, substitui essa parte pelo novo IP público.
echo "Atualizando a linha 'VITE_API_URL' no Dockerfile..."

# Primeiro, verifica se a linha existe para evitar erros se ela já tiver sido modificada ou não existir
if grep -q "RUN cd client && VITE_API_URL=http://" "$DOCKERFILE_PATH"; then
  # Usa sed para substituir o IP/localhost existente pelo novo IP
  sed -i "s#\(RUN cd client && VITE_API_URL=http://\)[0-9.]*:\([0-9]* npm run build\)#\1$PUBLIC_IP:\2#" "$DOCKERFILE_PATH"
  # Se a linha original for exatamente 'localhost', esta regex também funciona.
  sed -i "s#\(RUN cd client && VITE_API_URL=http://\)localhost:\([0-9]* npm run build\)#\1$PUBLIC_IP:\2#" "$DOCKERFILE_PATH"
  echo "Dockerfile atualizado com sucesso para VITE_API_URL=http://$PUBLIC_IP:3002 npm run build"
else
  echo "A linha 'RUN cd client && VITE_API_URL=http://localhost:3002 npm run build' (ou similar) não foi encontrada no Dockerfile."
  echo "Por favor, verifique o conteúdo do Dockerfile para garantir que a linha está correta."
  exit 1
fi

echo "Script concluído."
