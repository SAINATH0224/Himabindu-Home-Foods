# ====================================================
# HOMEFODS Complete AWS Deployment Script
# ====================================================
# This script will automatically deploy your entire website to AWS
# Usage: .\full-deploy.ps1 -bucketName "your-unique-bucket-name"
# ====================================================

param(
    [string]$bucketName = "homefods-website-2025"
)

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"

Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
Write-Host "â•‘  HOMEFODS Complete AWS Deployment Script      â•‘" -ForegroundColor Cyan
Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•`n" -ForegroundColor Cyan

Write-Host "Bucket Name: $bucketName" -ForegroundColor White
Write-Host "AWS Region: $AWS_REGION" -ForegroundColor White
Write-Host "`n"

# ====================================================
# STEP 0: Pre-flight Checks
# ====================================================
Write-Host "[0/7] Pre-flight Checks..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1
    Write-Host "âœ“ AWS CLI installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "âŒ AWS CLI not found!" -ForegroundColor Red
    Write-Host "Please install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS credentials not configured"
    }
    Write-Host "âœ“ AWS credentials configured" -ForegroundColor Green
} catch {
    Write-Host "âŒ AWS credentials not configured!" -ForegroundColor Red
    Write-Host "Please run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Check if project files exist
$requiredFiles = @("index.html", "menu.html", "signin.html", "signup.html", "ordernow.html", "dashboard.html")
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "âŒ Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "âœ“ All required files found" -ForegroundColor Green
Write-Host "`n"

# ====================================================
# STEP 1: Create S3 Bucket
# ====================================================
Write-Host "[1/7] Creating S3 Bucket..." -ForegroundColor Yellow

# Check if bucket exists
$bucketExists = $false
try {
    aws s3api head-bucket --bucket $bucketName --region $AWS_REGION 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $bucketExists = $true
        Write-Host "âš  Bucket already exists, will use existing bucket" -ForegroundColor Yellow
    }
} catch {
    # Bucket doesn't exist, will create it
}

if (-not $bucketExists) {
    try {
        aws s3 mb s3://$bucketName --region $AWS_REGION
        Write-Host "âœ“ S3 bucket created: $bucketName" -ForegroundColor Green
    } catch {
        Write-Host "âŒ Failed to create bucket. It might be taken or you don't have permissions." -ForegroundColor Red
        Write-Host "Try a different bucket name: .\full-deploy.ps1 -bucketName 'homefods-yourname-2025'" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n"

# ====================================================
# STEP 2: Enable Static Website Hosting
# ====================================================
Write-Host "[2/7] Configuring S3 for Website Hosting..." -ForegroundColor Yellow

# Enable static website hosting
aws s3 website s3://$bucketName --index-document index.html --error-document index.html --region $AWS_REGION

Write-Host "âœ“ Static website hosting enabled" -ForegroundColor Green

# Remove public access block
aws s3api put-public-access-block `
    --bucket $bucketName `
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" `
    --region $AWS_REGION

Write-Host "âœ“ Public access block removed" -ForegroundColor Green

# Create and apply bucket policy
$bucketPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$bucketName/*"
    }
  ]
}
"@

$bucketPolicy | Out-File -FilePath "temp-bucket-policy.json" -Encoding utf8
aws s3api put-bucket-policy --bucket $bucketName --policy file://temp-bucket-policy.json --region $AWS_REGION
Remove-Item "temp-bucket-policy.json"

Write-Host "âœ“ Bucket policy applied (public read access)" -ForegroundColor Green

$s3WebsiteUrl = "http://$bucketName.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "âœ“ S3 Website URL: $s3WebsiteUrl" -ForegroundColor Cyan

Write-Host "`n"

# ====================================================
# STEP 3: Upload Files to S3
# ====================================================
Write-Host "[3/7] Uploading files to S3..." -ForegroundColor Yellow

# Sync all files
aws s3 sync . s3://$bucketName `
    --exclude ".git/*" `
    --exclude "node_modules/*" `
    --exclude "*.md" `
    --exclude "*.ps1" `
    --exclude ".gitignore" `
    --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" `
    --exclude "api-server/*" `
    --exclude "temp-*" `
    --delete `
    --region $AWS_REGION

Write-Host "âœ“ Files uploaded" -ForegroundColor Green

# Set correct content types
Write-Host "  Setting content types..." -ForegroundColor Gray

aws s3 cp s3://$bucketName s3://$bucketName --recursive `
    --metadata-directive REPLACE `
    --content-type "text/html" `
    --exclude "*" `
    --include "*.html" `
    --region $AWS_REGION | Out-Null

aws s3 cp s3://$bucketName s3://$bucketName --recursive `
    --metadata-directive REPLACE `
    --content-type "image/jpeg" `
    --exclude "*" `
    --include "*.jpg" `
    --region $AWS_REGION | Out-Null

Write-Host "âœ“ Content types configured" -ForegroundColor Green

Write-Host "`n"

# ====================================================
# STEP 4: Test S3 Website
# ====================================================
Write-Host "[4/7] Testing S3 Website..." -ForegroundColor Yellow

Start-Sleep -Seconds 3
try {
    $response = Invoke-WebRequest -Uri $s3WebsiteUrl -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "âœ“ S3 website is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "âš  S3 website test inconclusive (may still work)" -ForegroundColor Yellow
}

Write-Host "`n"

# ====================================================
# STEP 5: Create CloudFront Distribution
# ====================================================
Write-Host "[5/7] Creating CloudFront Distribution..." -ForegroundColor Yellow
Write-Host "  This may take 10-15 minutes..." -ForegroundColor Gray

# Check if CloudFront distribution already exists
$existingDistribution = aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[0].DomainName=='$bucketName.s3-website-$AWS_REGION.amazonaws.com'].Id" --output text 2>&1

if ($existingDistribution -and $existingDistribution -ne "") {
    $CLOUDFRONT_ID = $existingDistribution
    Write-Host "âš  CloudFront distribution already exists: $CLOUDFRONT_ID" -ForegroundColor Yellow
} else {
    # Create CloudFront distribution config
    $cloudfrontConfig = @"
{
  "CallerReference": "homefods-$(Get-Date -Format 'yyyyMMddHHmmss')",
  "Comment": "HOMEFODS Website Distribution",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$bucketName",
        "DomainName": "$bucketName.s3-website-$AWS_REGION.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultRootObject": "index.html",
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$bucketName",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 3,
      "Items": ["GET", "HEAD", "OPTIONS"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "PriceClass": "PriceClass_All"
}
"@

    $cloudfrontConfig | Out-File -FilePath "temp-cloudfront-config.json" -Encoding utf8

    try {
        $distribution = aws cloudfront create-distribution --distribution-config file://temp-cloudfront-config.json --output json | ConvertFrom-Json
        $CLOUDFRONT_ID = $distribution.Distribution.Id
        Remove-Item "temp-cloudfront-config.json"
        Write-Host "âœ“ CloudFront distribution created: $CLOUDFRONT_ID" -ForegroundColor Green
    } catch {
        Write-Host "âŒ Failed to create CloudFront distribution" -ForegroundColor Red
        Remove-Item "temp-cloudfront-config.json" -ErrorAction SilentlyContinue
        exit 1
    }
}

Write-Host "`n"

# ====================================================
# STEP 6: Get CloudFront Domain Name
# ====================================================
Write-Host "[6/7] Getting CloudFront Information..." -ForegroundColor Yellow

$cloudfrontDomain = aws cloudfront get-distribution --id $CLOUDFRONT_ID --query "Distribution.DomainName" --output text

Write-Host "âœ“ CloudFront Domain: $cloudfrontDomain" -ForegroundColor Cyan
Write-Host "âœ“ CloudFront URL: https://$cloudfrontDomain" -ForegroundColor Cyan

Write-Host "`n"

# ====================================================
# STEP 7: Wait for CloudFront Deployment
# ====================================================
Write-Host "[7/7] Waiting for CloudFront deployment..." -ForegroundColor Yellow
Write-Host "  This typically takes 10-15 minutes. Please be patient..." -ForegroundColor Gray

$maxWaitMinutes = 20
$checkIntervalSeconds = 30
$elapsedMinutes = 0

while ($elapsedMinutes -lt $maxWaitMinutes) {
    $status = aws cloudfront get-distribution --id $CLOUDFRONT_ID --query "Distribution.Status" --output text
    
    if ($status -eq "Deployed") {
        Write-Host "âœ“ CloudFront distribution is deployed!" -ForegroundColor Green
        break
    }
    
    Write-Host "  Status: $status - Elapsed: $elapsedMinutes min" -ForegroundColor Gray
    Start-Sleep -Seconds $checkIntervalSeconds
    $elapsedMinutes += ($checkIntervalSeconds / 60)
}

if ($status -ne "Deployed") {
    Write-Host "âš  Deployment is still in progress. Check AWS Console for status." -ForegroundColor Yellow
}

Write-Host "`n"

# ====================================================
# Deployment Summary
# ====================================================
Write-Host "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Green
Write-Host "â•‘          Deployment Complete! ðŸŽ‰                â•‘" -ForegroundColor Green
Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•`n" -ForegroundColor Green

Write-Host "Your Website URLs:" -ForegroundColor Cyan
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Gray
Write-Host "S3 Website (HTTP):" -ForegroundColor White
Write-Host "  $s3WebsiteUrl" -ForegroundColor Yellow
Write-Host "`nCloudFront (HTTPS - Use this one!):" -ForegroundColor White
Write-Host "  https://$cloudfrontDomain" -ForegroundColor Yellow
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”`n" -ForegroundColor Gray

Write-Host "AWS Resources Created:" -ForegroundColor Cyan
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Gray
Write-Host "âœ“ S3 Bucket: $bucketName" -ForegroundColor Green
Write-Host "âœ“ CloudFront Distribution ID: $CLOUDFRONT_ID" -ForegroundColor Green
Write-Host "âœ“ Static Website Hosting: Enabled" -ForegroundColor Green
Write-Host "âœ“ Public Access: Configured" -ForegroundColor Green
Write-Host "âœ“ HTTPS: Enabled via CloudFront" -ForegroundColor Green
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”`n" -ForegroundColor Gray

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Gray
Write-Host "1. Test your website: https://$cloudfrontDomain" -ForegroundColor White
Write-Host "2. Add to Firebase Authorized Domains:" -ForegroundColor White
Write-Host "   - Go to: https://console.firebase.google.com" -ForegroundColor Gray
Write-Host "   - Project: home-foods-9f024" -ForegroundColor Gray
Write-Host "   - Authentication â†’ Settings â†’ Authorized Domains" -ForegroundColor Gray
Write-Host "   - Add: $cloudfrontDomain" -ForegroundColor Gray
Write-Host "3. (Optional) Configure custom domain in CloudFront" -ForegroundColor White
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”`n" -ForegroundColor Gray

Write-Host "Save These Values:" -ForegroundColor Cyan
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Gray
Write-Host "S3_BUCKET=$bucketName" -ForegroundColor Yellow
Write-Host "CLOUDFRONT_ID=$CLOUDFRONT_ID" -ForegroundColor Yellow
Write-Host "CLOUDFRONT_DOMAIN=$cloudfrontDomain" -ForegroundColor Yellow
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”`n" -ForegroundColor Gray

Write-Host "For future updates, use:" -ForegroundColor Cyan
Write-Host "  .\update-site.ps1 -bucketName '$bucketName' -cloudfrontId '$CLOUDFRONT_ID'" -ForegroundColor Yellow

Write-Host "`nðŸš€ Deployment completed successfully!`n" -ForegroundColor Green

# Save configuration
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$config = @"
# HOMEFODS AWS Configuration
# Generated: $timestamp
S3_BUCKET=$bucketName
CLOUDFRONT_ID=$CLOUDFRONT_ID
CLOUDFRONT_DOMAIN=$cloudfrontDomain
AWS_REGION=$AWS_REGION
S3_WEBSITE_URL=$s3WebsiteUrl
"@

$config | Out-File -FilePath "aws-config.txt" -Encoding utf8
Write-Host "Configuration saved to: aws-config.txt" -ForegroundColor Gray

