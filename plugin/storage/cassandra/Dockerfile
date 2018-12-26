FROM cassandra:3.11

COPY schema/* /cassandra-schema/

ENV CQLSH_HOST=cassandra
ENV CQLSH_PORT=9042
ENTRYPOINT ["/cassandra-schema/docker.sh"]
