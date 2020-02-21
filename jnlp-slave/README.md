

cat <<EOF > Dockerfile
FROM jenkins/jnlp-slave:3.27-1
EOF

docker build -t medined/jnlp-slave:0.0.1 .
docker run -it --rm medined/jnlp-slave:0.0.1
docker login
docker push medined/jnlp-slave:0.0.1
docker run -it --rm docker.io/medined/jnlp-slave:0.0.1
