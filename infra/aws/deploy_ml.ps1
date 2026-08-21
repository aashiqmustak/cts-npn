# ==============================================================================
# Script: deploy_ml.ps1
# Description: Builds, tags, pushes ML container to ECR, and deploys to App Runner
# ==============================================================================

param (
    [string]$Region = "us-east-1",
    [string]$RepositoryName = "cts-npn-ml",
    [string]$ServiceName = "cts-npn-ml-service",
    [string]$ImageTag = "latest"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CTS-NPN: Litestar ML Model Deployment to AWS App Runner   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check AWS CLI Authentication
Write-Host "`n[1/5] Fetching AWS Account ID..." -ForegroundColor Yellow
$AccountId = aws sts get-caller-identity --query "Account" --output text
if (-not $AccountId) {
    Write-Error "Failed to get AWS Account ID. Please run 'aws configure' and try again."
    exit 1
}
Write-Host "AWS Account ID: $AccountId" -ForegroundColor Green

$EcrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com/$RepositoryName"

# 2. Ensure ECR Repository Exists
Write-Host "`n[2/5] Checking/Creating ECR Repository '$RepositoryName'..." -ForegroundColor Yellow
aws ecr describe-repositories --repository-names $RepositoryName --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Repository does not exist. Creating..." -ForegroundColor Cyan
    aws ecr create-repository --repository-name $RepositoryName --region $Region | Out-Null
}

# 3. Log in to Amazon ECR
Write-Host "`n[3/5] Authenticating Docker with Amazon ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker login to ECR failed."
    exit 1
}

# 4. Build and Push Docker Image
Write-Host "`n[4/5] Building Docker Image with Litestar & ML Models..." -ForegroundColor Yellow
docker build -t "$RepositoryName`:$ImageTag" -f infra/docker/ml.Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit 1
}

docker tag "$RepositoryName`:$ImageTag" "$EcrUri`:$ImageTag"

Write-Host "Pushing Docker image to Amazon ECR: $EcrUri`:$ImageTag..." -ForegroundColor Yellow
docker push "$EcrUri`:$ImageTag"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker push failed."
    exit 1
}

# 5. Check/Deploy App Runner Service
Write-Host "`n[5/5] Checking AWS App Runner Service '$ServiceName'..." -ForegroundColor Yellow
$ServiceArn = aws apprunner list-services --region $Region --query "ServiceSummaryList[?ServiceName=='$ServiceName'].ServiceArn" --output text

if ($ServiceArn) {
    Write-Host "Service exists ($ServiceArn). Triggering new deployment..." -ForegroundColor Cyan
    aws apprunner start-deployment --service-arn $ServiceArn --region $Region
} else {
    Write-Host "Service does not exist yet. Please create it via AWS Console or provide IAM Access Role ARN." -ForegroundColor Yellow
    Write-Host "Image URI for Console: $EcrUri`:$ImageTag" -ForegroundColor Green
}

Write-Host "`n[DONE] Deployment process completed successfully!" -ForegroundColor Green
