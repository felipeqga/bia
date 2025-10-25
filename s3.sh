Bash
function envio_s3() {
    echo "Fazendo envio para o s3..."
    echo "Iniciando envio..."
    aws s3 sync ./bia/client/build/ s3://desafios-fundamentais-bia --profile fundamentos
    echo "Envio finalizado"
}
