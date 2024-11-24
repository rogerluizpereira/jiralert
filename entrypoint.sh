#!/bin/sh

echo "Iniciando $0"
#echo "Container: $(basename $(cat /proc/self/cgroup | grep 'memory'))"
# Configura o script para terminar imediatamente em caso de erro, para que
# não continue executando de forma inconsistente e/ou imprevisível
set -e

# Adiciona a saída do stdout e stderr também para o arquivo para 
# que os logs deste script possam ser analisadas mesmo quando a 
# saída do console não possa ser capturada
exec > >(tee -a $0.log)
exec 2>&1

# Função para executar o Gracefull Shutdown, ou seja quando o container receber um sinal
# de término, seja de fora do container, ou porque alguma evento a encerrou executa os 
# processos de finalização para que o container seja finalizado coreetamente   
terminating() {
    echo " ----"
    if [ -n "$APP_EXIT_CODE" ]; then
        echo " Executando finalização a partir do encerramento do processo. PID: $APP_PID | APP_EXIT_CODE: $APP_EXIT_CODE."
    else
        echo " Executando finalização a partir do encerramento do container."
        kill -TERM $APP_PID
        echo " Processo da aplicação encerrado."
    fi
    rm -f $APP_PATH/config/*.tmp.*
    echo " Finalização concluída."
    echo " ----"
    sync 
    wait
}
# Captura os sinais de término e executa o processo de finalização do container
trap terminating SIGTERM SIGINT SIGQUIT SIGHUP SIGABRT SIGSEGV

echo "Inicializando o container..."

APP_PATH=/jiralert

# Carrega o arquivo de template de configuração
CONFIG_FILE="$APP_PATH/config/jiralert.yml"
# Cria o arquivo temporário que será usado para carregar as configurações da aplicação
TEMP_CONFIG_FILE=$(mktemp config.tmp.XXXXXX -p $APP_PATH/config/)

# Obtem as configurações comuns de variáveis de ambiente e segredos 
# do cofre evitando a exposição dos segredos em variáveis de ambiente
# atualizando o arquivo de configuração que será usado pela aplicação
"$APP_PATH/envconfigx" $AWS_PROFILE $CONFIG_FILE $TEMP_CONFIG_FILE
APP_PID=$!
APP_EXIT_CODE=$?

# Agenda a exclusão do arquivo para 5 segundos, para que o arquivo permaneça em disco
# o menor tempo possível, evitado exposição de credenciais.
#nohup sh -c "sleep 5 && rm -f $TEMP_CONFIG_FILE" &

if [ "$APP_EXIT_CODE" -ne 0 ]; then
    echo "Falha na substituição das configurações."
    terminating
fi

# Inicia aplicações e daemons pré-requisito
echo "Iniciando pré-requisitos"
# Inicia a aplicação principal, mantendo o PID para controle
"$APP_PATH/jiralert" -hash-jira-label -config $TEMP_CONFIG_FILE --log.format=json &
APP_PID=$!
echo "Aplicação iniciada, PID: $APP_PID"

# Aguarda a finalização do aplicação principal, mantendo o PID para controle
# Se o container receber um sinal de encerramento antes da aplicação, o terminating será executado
# pelo trap caso comntrário, será executado intencionalmente após o término da aplicação principal.  
wait $APP_PID && APP_EXIT_CODE=$? || APP_EXIT_CODE=$?
echo "Aplicação encerrada, APP_EXIT_CODE: $APP_EXIT_CODE"
if [ "$APP_EXIT_CODE" -lt 129 ]; then
    terminating 
fi
echo "Finalizado $0"
exit $APP_EXIT_CODE