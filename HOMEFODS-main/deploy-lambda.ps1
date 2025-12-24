# ====================================================
# Deploy AWS Lambda + API Gateway for Firebase Config
# ====================================================

param(
    [string]$functionName = "homefods-firebase-config",
    [string]$region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Deploying Lambda Function ===" -ForegroundColor Cyan

# Step 1: Create IAM role for Lambda
Write-Host "[1/6] Creating IAM role..." -ForegroundColor Yellow

$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@

$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding utf8

try {
    aws iam create-role --role-name "$functionName-role" --assume-role-policy-document file://trust-policy.json 2>$null
    Write-Host "Role created" -ForegroundColor Green
} catch {
    Write-Host "Role already exists" -ForegroundColor Yellow
}

# Attach basic Lambda execution policy
aws iam attach-role-policy --role-name "$functionName-role" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

Remove-Item "trust-policy.json"

# Wait for role to propagate
Write-Host "Waiting for IAM role to propagate..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Step 2: Get account ID and construct role ARN
Write-Host "[2/6] Getting AWS account info..." -ForegroundColor Yellow

$accountId = aws sts get-caller-identity --query Account --output text
$roleArn = "arn:aws:iam::${accountId}:role/$functionName-role"
Write-Host "Role ARN: $roleArn" -ForegroundColor Gray

# Step 3: Create deployment package
Write-Host "[3/6] Creating deployment package..." -ForegroundColor Yellow

if (Test-Path "lambda-function.zip") {
    Remove-Item "lambda-function.zip"
}

Compress-Archive -Path "lambda-firebase-config.js" -DestinationPath "lambda-function.zip"
Write-Host "Deployment package created" -ForegroundColor Green

# Step 4: Create or update Lambda function
Write-Host "[4/6] Deploying Lambda function..." -ForegroundColor Yellow

try {
    $lambdaExists = aws lambda get-function --function-name $functionName --region $region 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        # Update existing function
        aws lambda update-function-code `
            --function-name $functionName `
            --zip-file fileb://lambda-function.zip `
            --region $region
        Write-Host "Lambda function updated" -ForegroundColor Green
    }
} catch {
    # Create new function
    aws lambda create-function `
        --function-name $functionName `
        --runtime nodejs20.x `
        --role $roleArn `
        --handler lambda-firebase-config.handler `
        --zip-file fileb://lambda-function.zip `
        --region $region
    Write-Host "Lambda function created" -ForegroundColor Green
}

# Step 5: Create API Gateway
Write-Host "[5/6] Creating API Gateway..." -ForegroundColor Yellow

# Check if API already exists
$existingApi = aws apigatewayv2 get-apis --query "Items[?Name=='$functionName-api'].ApiId" --output text --region $region

if ($existingApi) {
    $apiId = $existingApi
    Write-Host "Using existing API: $apiId" -ForegroundColor Yellow
} else {
    $apiId = aws apigatewayv2 create-api `
        --name "$functionName-api" `
        --protocol-type HTTP `
        --query ApiId `
        --output text `
        --region $region
    Write-Host "API Gateway created: $apiId" -ForegroundColor Green
}

# Configure CORS
aws apigatewayv2 update-api `
    --api-id $apiId `
    --cors-configuration "AllowOrigins=https://d3fe13j8cyielm.cloudfront.net,AllowMethods=GET,OPTIONS,AllowHeaders=Content-Type" `
    --region $region

# Create integration
$integrationId = aws apigatewayv2 create-integration `
    --api-id $apiId `
    --integration-type AWS_PROXY `
    --integration-uri "arn:aws:lambda:${region}:${accountId}:function:$functionName" `
    --payload-format-version 2.0 `
    --query IntegrationId `
    --output text `
    --region $region

# Create route
aws apigatewayv2 create-route `
    --api-id $apiId `
    --route-key "GET /firebase-config" `
    --target "integrations/$integrationId" `
    --region $region 2>$null

# Create stage
aws apigatewayv2 create-stage `
    --api-id $apiId `
    --stage-name "prod" `
    --auto-deploy `
    --region $region 2>$null

# Add Lambda permission for API Gateway
aws lambda add-permission `
    --function-name $functionName `
    --statement-id "apigateway-invoke" `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${region}:${accountId}:${apiId}/*/*" `
    --region $region 2>$null

# Step 6: Get API endpoint
Write-Host "[6/6] Getting API endpoint..." -ForegroundColor Yellow

$apiEndpoint = "https://${apiId}.execute-api.${region}.amazonaws.com/prod/firebase-config"

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "`nAPI Endpoint:" -ForegroundColor Cyan
Write-Host "  $apiEndpoint" -ForegroundColor Yellow
Write-Host "`nUse this URL in your HTML files to fetch Firebase config securely." -ForegroundColor Gray

# Save configuration
$config = @"
# Lambda Configuration
LAMBDA_FUNCTION_NAME=$functionName
API_ID=$apiId
API_ENDPOINT=$apiEndpoint
REGION=$region
DEPLOYMENT_DATE=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$config | Out-File -FilePath "lambda-config.txt" -Encoding utf8
Write-Host "`nConfiguration saved to: lambda-config.txt`n" -ForegroundColor Gray

# Cleanup
Remove-Item "lambda-function.zip"
