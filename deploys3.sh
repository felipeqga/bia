bash
AMBIENTE=$1
API_URL="http://32.18.123.12"
echo "Vou iniciar deploy no ambiente: $AMBIENTE"
echo "O endereco da api sera: $API_URL"

#check if my var AMBIENTE is equals to hom ou prd
if [ "$AMBIENTE" != "hom" ] && [ "$AMBIENTE" != "prd" ]; then
    echo "Ambiente invalido"
    exit 1
fi

. react.sh
. s3.sh

echo "Fazendo deploy..."

build $API_URL
envio_s3

echo "Finalizado"
