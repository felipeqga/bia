url="http://bia-1260066125.us-east-1.elb.amazonaws.com/api/versao"
docker build -t check_disponibilidade -f Dockerfile_checkdisponibilidade .
docker run --rm -ti -e URL=$url check_disponibilidade
