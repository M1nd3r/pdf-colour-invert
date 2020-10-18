FROM node:lts as webapp-builder

WORKDIR /app
COPY webapp /app

RUN npm ci
RUN npm run build

FROM amd64/ubuntu:bionic

RUN apt update && apt install -y python3-pip ghostscript texlive-extra-utils imagemagick
COPY policy.xml /etc/ImageMagick-6/policy.xml

WORKDIR /app

COPY pdfinvert /app/pdfinvert
COPY requirements.txt /app
COPY application.yml /app
COPY nginx.conf.sigil /app

RUN pip3 install --trusted-host pypi.python.org -r requirements.txt

COPY --from=webapp-builder /app/public/ /app/pdfinvert/static/

RUN groupadd -r app && useradd --no-log-init -r -g app app
USER app

ENV PYTHONPATH /app

CMD ["/bin/bash", "-c", "gunicorn --bind=0.0.0.0:$PORT --workers=1 --threads=16 --timeout 1800 --graceful-timeout 400 pdfinvert.main"]
