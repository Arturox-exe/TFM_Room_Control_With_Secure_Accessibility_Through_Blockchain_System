FROM postgres:latest
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD root
COPY ./schema.sql /docker-entrypoint-initdb.d/init.sql