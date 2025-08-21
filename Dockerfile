FROM alpine:latest

RUN apk add --no-cache bash jq

WORKDIR /app

COPY team_scheduling.sh .

RUN chmod +x team_scheduling.sh

CMD ["bash", "./team_scheduling.sh"]
