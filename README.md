# SkyWatch

DevOps Final Project

A weather application deployed on AWS using:
- Terraform
- Ansible
- Kubernetes (K3s)
- Docker
- Helm
- GitHub Actions
- ArgoCD
- Prometheus and Grafana
## Run SkyWatch with Docker

### Prerequisites

- Docker installed and running

### Build the Docker image

From the project root directory:

```bash
cd app/frontend
docker build -t skywatch-frontend:1.0 .
```

### Run the container

```bash
docker run --rm -p 5000:5000 skywatch-frontend:1.0
```

### Open the application

Open the following URLs in your browser:

- Home page: http://localhost:5000
- Tel Aviv weather: http://localhost:5000/weather/tel-aviv
- Jerusalem weather: http://localhost:5000/weather/jerusalem

To stop the container, press `Ctrl+C` in the terminal.