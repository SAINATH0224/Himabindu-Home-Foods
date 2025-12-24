# ====================================================
# HOMEFODS Update Deployment Script
# ====================================================
# Use this script to update your website after initial deployment
# Usage: .\update-site.ps1 -bucketName "your-bucket-name" -cloudfrontId "E1234567890ABC"
# ====================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$bucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$cloudfrontId
)

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     HOMEFODS Website Update Script            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Updating: $bucketName" -ForegroundColor White
Write-Host "CloudFront: $cloudfrontId`n" -ForegroundColor White

# ====================================================
# STEP 1: Upload Updated Files
# ====================================================
Write-Host "[1/3] Uploading updated files to S3..." -ForegroundColor Yellow

aws s3 sync . s3://$bucketName `
    --exclude ".git/*" `
    --exclude "node_modules/*" `
    --exclude "*.md" `
    --exclude "*.ps1" `
    --exclude ".gitignore" `
    --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" `
    --exclude "api-server/*" `
    --exclude "aws-config.txt" `
    --delete `
    --region $AWS_REGION

Write-Host "✓ Files uploaded" -ForegroundColor Green

# Set content types
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

Write-Host "✓ Content types updated" -ForegroundColor Green
Write-Host "`n"

# ====================================================
# STEP 2: Invalidate CloudFront Cache
# ====================================================
Write-Host "[2/3] Clearing CloudFront cache..." -ForegroundColor Yellow

$invalidation = aws cloudfront create-invalidation `
    --distribution-id $cloudfrontId `
    --paths "/*" `
    --query 'Invalidation.Id' `
    --output text

Write-Host "✓ Cache invalidation created: $invalidation" -ForegroundColor Green
Write-Host "  (Changes will be live in 5-10 minutes)" -ForegroundColor Gray
Write-Host "`n"

# ====================================================
# STEP 3: Get URLs
# ====================================================
Write-Host "[3/3] Getting website URLs..." -ForegroundColor Yellow

$cloudfrontDomain = aws cloudfront get-distribution --id $cloudfrontId --query "Distribution.DomainName" --output text
$s3WebsiteUrl = "http://$bucketName.s3-website-$AWS_REGION.amazonaws.com"

Write-Host "✓ URLs retrieved" -ForegroundColor Green
Write-Host "`n"

# ====================================================
# Summary
# ====================================================
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Update Complete! 🎉                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Your Website URLs:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "CloudFront (HTTPS):" -ForegroundColor White
Write-Host "  https://$cloudfrontDomain" -ForegroundColor Yellow
Write-Host "`nS3 Website (HTTP):" -ForegroundColor White
Write-Host "  $s3WebsiteUrl" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "✓ Files updated on S3" -ForegroundColor Green
Write-Host "✓ CloudFront cache cleared" -ForegroundColor Green
Write-Host "✓ Changes will be live in 5-10 minutes`n" -ForegroundColor Green

Write-Host "Test your website: https://$cloudfrontDomain`n" -ForegroundColor Cyan
