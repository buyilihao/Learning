FROM redis:3-alpine
MAINTAINER voidman <voidman>

COPY redis.conf /data/redis.conf
COPY sentinel.conf /data/sentinel.conf
COPY start.sh /data/start.sh
RUN chmod +x /data/start.sh
RUN chown redis:redis /data/*
ENTRYPOINT ["sh","/data/start.sh"] 
CMD ["master"]
