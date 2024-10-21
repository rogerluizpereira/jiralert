# jiralert

docker compose up --build jiralert

curl -H "Content-type: application/json" -X POST -d '@EventSample-Firing.json' http://localhost:9097/alert

curl -H "Content-type: application/json" -X POST -d '@EventSample-Resolved.json' http://localhost:9097/alert
