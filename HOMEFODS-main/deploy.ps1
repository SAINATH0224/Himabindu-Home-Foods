# HOMEFODS Complete AWS Deployment Script
# Usage: .\deploy.ps1 -mode full (for first time deployment)
#        .\deploy.ps1 (for updates)

param(
    [string]$mode = "update",  # "full" for first deployment, "update" for subsequent
    [string]$bucketName = "homefods-website-2025"
)

Write-Host "`n=== HOMEFODS AWS Deployment ===" -ForegroundColor Green
Write-Host "Mode: $mode" -ForegroundColor Cyan
Write-Host "Bucket: $bucketName`n" -ForegroundColor Cyan

# Configuration
$S3_BUCKET = $bucketName
$AWS_REGION = "us-east-1"
$CLOUDFRONT_ID = ""  # Will be populated after CloudFront creation

# Check if AWS CLI is installed
$awsVersion = aws --version 2>$null
if (-not $awsVersion) {
    Write-Host "❌ AWS CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install it from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ AWS CLI found: $awsVersion" -ForegroundColor Green

# Step 1: Sync files to S3
Write-Host "`n[1/4] Uploading files to S3..." -ForegroundColor Yellow
try {
    aws s3 sync . s3://$S3_BUCKET `
        --exclude ".git/*" `
        --exclude "node_modules/*" `
        --exclude "*.md" `
        --exclude "*.ps1" `
        --exclude ".gitignore" `
        --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" `
        --exclude "api-server/*" `
        --delete `
        --region $AWS_REGION
    
    Write-Host "✓ Files uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to upload files" -ForegroundColor Red
    exit 1
}

# Step 2: Set correct content types for HTML files
Write-Host "`n[2/4] Setting content types for HTML files..." -ForegroundColor Yellow
aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET --recursive `
    --metadata-directive REPLACE `
    --content-type "text/html" `
    --exclude "*" `
    --include "*.html" `
    --region $AWS_REGION

Write-Host "✓ HTML content types set" -ForegroundColor Green

# Step 3: Set correct content types for images
Write-Host "`n[3/4] Setting content types for images..." -ForegroundColor Yellow
aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET --recursive `
    --metadata-directive REPLACE `
    --content-type "image/jpeg" `
    --exclude "*" `
    --include "*.jpg" `
    --region $AWS_REGION

Write-Host "✓ Image content types set" -ForegroundColor Green

# Step 4: Invalidate CloudFront cache (if CloudFront ID is provided)
if ($CLOUDFRONT_ID) {
    Write-Host "`n[4/4] Invalidating CloudFront cache..." -ForegroundColor Yellow
    try {
        $invalidation = aws cloudfront create-invalidation `
            --distribution-id $CLOUDFRONT_ID `
            --paths "/*" `
            --query 'Invalidation.Id' `
            --output text
        
        Write-Host "✓ CloudFront cache invalidation created: $invalidation" -ForegroundColor Green
        Write-Host "  (This may take 5-15 minutes to complete)" -ForegroundColor Gray
    } catch {
        Write-Host "⚠ CloudFront invalidation skipped (check distribution ID)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[4/4] Skipping CloudFront invalidation (no distribution ID set)" -ForegroundColor Gray
}

# Display results
Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "✓ Files uploaded to S3" -ForegroundColor Green
Write-Host "✓ Content types configured" -ForegroundColor Green

# Get S3 website URL
$s3Url = "http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "`nYour website URLs:" -ForegroundColor Cyan
Write-Host "  S3 Website: $s3Url" -ForegroundColor White

if ($CLOUDFRONT_ID) {
    Write-Host "  CloudFront: Check your CloudFront distribution" -ForegroundColor White
}

Write-Host "`nDeployment timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "`n🚀 Deployment successful!`n" -ForegroundColor Green
