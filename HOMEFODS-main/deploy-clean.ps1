# ====================================================
# HOMEFODS Complete AWS Deployment Script
# ====================================================
param(
    [string]$bucketName = "homefods-website-2025"
)

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"

Write-Host "`n=== HOMEFODS AWS Deployment ===" -ForegroundColor Cyan
Write-Host "Bucket: $bucketName" -ForegroundColor White
Write-Host "Region: $AWS_REGION`n" -ForegroundColor White

# ====================================================
# STEP 1: Create S3 Bucket
# ====================================================
Write-Host "[1/5] Creating S3 Bucket..." -ForegroundColor Yellow

$bucketExists = $false
try {
    aws s3api head-bucket --bucket $bucketName --region $AWS_REGION 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $bucketExists = $true
        Write-Host "Bucket already exists" -ForegroundColor Yellow
    }
} catch {}

if (-not $bucketExists) {
    aws s3 mb s3://$bucketName --region $AWS_REGION
    Write-Host "Bucket created" -ForegroundColor Green
}

# ====================================================
# STEP 2: Configure Website Hosting
# ====================================================
Write-Host "[2/5] Configuring Website Hosting..." -ForegroundColor Yellow

aws s3 website s3://$bucketName --index-document index.html --error-document index.html --region $AWS_REGION

aws s3api put-public-access-block --bucket $bucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" --region $AWS_REGION

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

$bucketPolicy | Out-File -FilePath "temp-policy.json" -Encoding utf8
aws s3api put-bucket-policy --bucket $bucketName --policy file://temp-policy.json --region $AWS_REGION
Remove-Item "temp-policy.json"

$s3WebsiteUrl = "http://$bucketName.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "Website configured: $s3WebsiteUrl" -ForegroundColor Green

# ====================================================
# STEP 3: Upload Files
# ====================================================
Write-Host "[3/5] Uploading files..." -ForegroundColor Yellow

aws s3 sync . s3://$bucketName --exclude ".git/*" --exclude "node_modules/*" --exclude "*.md" --exclude "*.ps1" --exclude ".gitignore" --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" --exclude "api-server/*" --delete --region $AWS_REGION

Write-Host "Files uploaded" -ForegroundColor Green

# ====================================================
# STEP 4: Create CloudFront Distribution
# ====================================================
Write-Host "[4/5] Creating CloudFront Distribution..." -ForegroundColor Yellow

$existingDistribution = aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[0].DomainName=='$bucketName.s3-website-$AWS_REGION.amazonaws.com'].Id" --output text 2>&1

if ($existingDistribution -and $existingDistribution -ne "") {
    $CLOUDFRONT_ID = $existingDistribution
    Write-Host "Using existing distribution: $CLOUDFRONT_ID" -ForegroundColor Yellow
} else {
    $callerRef = "homefods-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $cloudfrontConfig = @"
{
  "CallerReference": "$callerRef",
  "Comment": "HOMEFODS Website",
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

    $cloudfrontConfig | Out-File -FilePath "temp-cf.json" -Encoding utf8
    $distribution = aws cloudfront create-distribution --distribution-config file://temp-cf.json --output json | ConvertFrom-Json
    $CLOUDFRONT_ID = $distribution.Distribution.Id
    Remove-Item "temp-cf.json"
    Write-Host "CloudFront created: $CLOUDFRONT_ID" -ForegroundColor Green
}

# ====================================================
# STEP 5: Get CloudFront Domain
# ====================================================
Write-Host "[5/5] Getting CloudFront information..." -ForegroundColor Yellow

$cloudfrontDomain = aws cloudfront get-distribution --id $CLOUDFRONT_ID --query "Distribution.DomainName" --output text

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "`nYour Website:" -ForegroundColor Cyan
Write-Host "  https://$cloudfrontDomain" -ForegroundColor Yellow
Write-Host "`nS3 Bucket: $bucketName" -ForegroundColor White
Write-Host "CloudFront ID: $CLOUDFRONT_ID" -ForegroundColor White
Write-Host "`nNote: CloudFront may take 10-15 minutes to fully deploy." -ForegroundColor Gray

# Save configuration
$config = @"
S3_BUCKET=$bucketName
CLOUDFRONT_ID=$CLOUDFRONT_ID
CLOUDFRONT_DOMAIN=$cloudfrontDomain
AWS_REGION=$AWS_REGION
DEPLOYMENT_DATE=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$config | Out-File -FilePath "aws-config.txt" -Encoding utf8
Write-Host "`nConfiguration saved to: aws-config.txt`n" -ForegroundColor Gray
