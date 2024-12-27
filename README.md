# jiralert

docker compose up --build jiralert

curl -H "Content-type: application/json" -X POST -d '@EventSample-Firing.json' http://localhost:9097/alert

curl -H "Content-type: application/json" -X POST -d '@EventSample-Resolved.json' http://localhost:9097/alert


para pegar as credenciais temporárias para o deploy
aws configure export-credentials --profile root

Para validação do fluxo ( pipeline ) de envio de alertas
https://www.prometheus.io/webtools/alerting/routing-tree-editor/

Ferramenta para verificação da config do alertmanager
./amtool check-config alertmanager.yml