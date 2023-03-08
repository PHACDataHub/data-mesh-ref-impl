FROM alpine:latest

RUN apk --no-cache add curl bash

RUN which crond && \
    rm -rf /etc/periodic

COPY conf/cron/crontab /var/spool/cron/crontabs/root/.

COPY conf/cron/entrypoint.sh .
RUN chmod +x /entrypoint.sh

COPY scripts/utils/download/download_current_rss.sh .
RUN chmod +x /download_current_rss.sh

ENTRYPOINT ["/entrypoint.sh"]

# source: `docker run --rm -it alpine  crond -h`
# -f | Foreground
# -l N | Set log level. Most verbose 0, default 8
CMD ["crond", "-f", "-l", "2"]