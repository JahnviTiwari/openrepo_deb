# Start with a node.js build image to compile the vue.js app distributables
FROM node:20.14.0 AS vuebuilder

WORKDIR /build/openrepo/

COPY frontend/ ./

RUN npm install && \
    npm run build

# Web app is compiled now to /build/openrepo/dist/


# Now build the production image
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
      apt-utils          \
      createrepo-c       \
      curl               \
      git                \   
      gpg                \
      gzip               \
      libapt-pkg-dev     \
      libpq-dev          \
      python3            \
      python3-pip        \
      python3-venv       \
      nginx
      
WORKDIR /app


# Copy the requirements.txt first and install dependencies, so that this can be cached
COPY web/requirements.txt ./django/requirements.txt
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN ln -s /usr/bin/createrepo_c /usr/bin/createrepo && \
    pip3 install --no-cache-dir -r django/requirements.txt && \
    mkdir -p /var/lib/openrepo/packages/

# Copy compiled vue app
COPY --from=vuebuilder /build/openrepo/dist ./frontend-dist/

# Copy Django app and configuration
COPY web ./django
COPY deploy/nginx/nginx.conf.prod /etc/nginx/nginx.conf
COPY deploy/run_openrepoweb /usr/bin/

RUN ./django/manage.py collectstatic --noinput

#CMD ["/usr/bin/run_openrepoweb"]
#EXPOSE 8000
