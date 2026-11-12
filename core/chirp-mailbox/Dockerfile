# A caixa postal do Chirp numa imagem de contêiner. O contexto é a pasta core/:
#   docker build -f chirp-mailbox/Dockerfile -t chirp-mailbox core
#   docker run -d --name chirp-mailbox -p 47474:47474/udp -v chirp-mailbox:/data \
#     chirp-mailbox run --data /data --public <IP público>:47474
#   docker exec chirp-mailbox chirp-mailbox pair --data /data
FROM docker.io/library/rust:1-slim-bookworm AS build
WORKDIR /src
# Quantos trabalhos o cargo roda ao mesmo tempo (vazio: um por núcleo).
ARG CARGO_BUILD_JOBS
COPY . .
# Só a caixa: o núcleo do app (e as dependências dele) fica fora da compilação.
RUN sed -i 's/^members = .*/members = ["chirp-mailbox"]/' Cargo.toml \
    && cargo build --release -p chirp_mailbox --bin chirp-mailbox

FROM docker.io/library/debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --home-dir /data mailbox \
    && mkdir /data && chown mailbox:mailbox /data && chmod 700 /data
COPY --from=build /src/target/release/chirp-mailbox /usr/bin/chirp-mailbox
USER mailbox
VOLUME /data
EXPOSE 47474/udp
ENTRYPOINT ["chirp-mailbox"]
CMD ["run", "--data", "/data"]
