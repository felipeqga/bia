#!/bin/bash
function envio_s3() {
    echo "Fazendo envio para o s3..."
    echo "Iniciando envio..."
    aws s3 sync ./bia/client/build/ s3://desafios-fundamentais-bia-1762481467
    echo "Envio finalizado"
}
