# Flask ECS App

A containerized Flask application deployed to AWS ECS Fargate with a fully automated CI/CD pipeline using GitHub Actions.

## Architecture

```
GitHub Push → GitHub Actions → Build Docker Image → Push to ECR → Deploy to ECS Fargate → ALB
```

## Tech Stack

- **Application:** Python, Flask, Gunicorn
- **Container:** Docker (multi-stage build)
- **Registry:** Amazon ECR
- **Compute:** Amazon ECS Fargate
- **Load Balancer:** Application Load Balancer (ALB)
- **CI/CD:** GitHub Actions with OIDC authentication
- **Region:** us-east-2

## How It Works

1. Push code to `main` branch
2. GitHub Actions automatically triggers the pipeline
3. Docker image is built and tagged with the commit SHA
4. Image is pushed to Amazon ECR
5. ECS task definition is updated with the new image
6. ECS service deploys the new task and waits for stability
7. ALB routes traffic to the running container

## Endpoints

| Route | Description |
|-------|-------------|
| `/` | App info and container hostname |
| `/health` | Health check endpoint |

## Local Development

```bash
python -m venv venv
.\venv\Scripts\Activate    # Windows
pip install -r requirements.txt
python app.py
```

## Run with Docker

```bash
docker build -t flask-ecs-app .
docker run -p 5000:5000 flask-ecs-app
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) handles the full build and deploy cycle. Authentication uses OIDC — no stored AWS credentials.

**Required GitHub Variables:**
- `AWS_ROLE_ARN` — IAM role ARN for GitHub Actions to assume

## Author

**Cameron Blue** — [GitHub](https://github.com/CamBlue)
