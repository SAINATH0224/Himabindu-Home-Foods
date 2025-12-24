# HOMEFODS AWS CLI Deployment Guide

## 🚀 Quick Start - Complete Automated Deployment

This guide will help you deploy your HOMEFODS website to AWS using command line.

---

## ✅ Prerequisites (5 minutes)

### 1. Install AWS CLI

**For Windows:**

1. Download: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run the installer
3. Restart PowerShell

**Verify installation:**
```powershell
aws --version
# Should show: aws-cli/2.x.x
```

### 2. Get AWS Access Keys

1. Go to AWS Console: https://console.aws.amazon.com
2. Click your name (top right) → **Security credentials**
3. Scroll to **"Access keys"** → Click **"Create access key"**
4. Select: **Command Line Interface (CLI)**
5. Click **Next** → **Create access key**
6. **COPY BOTH KEYS** (save them somewhere safe)

### 3. Configure AWS CLI

```powershell
aws configure
```

Enter when prompted:
```
AWS Access Key ID: AKIAXXXXXXXXXXXXXXXX (paste yours)
AWS Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (paste yours)
Default region name: us-east-1
Default output format: json
```

**Verify configuration:**
```powershell
aws sts get-caller-identity
# Should show your account info
```

---

## 🎯 Option 1: One-Command Full Deployment (RECOMMENDED)

### Deploy Everything Automatically

```powershell
# Navigate to your project folder
cd C:\Users\ASUS\Desktop\HOMEFODS-main

# Run the deployment script
.\full-deploy.ps1 -bucketName "homefods-website-2025"
```

**If bucket name is taken, use a unique name:**
```powershell
.\full-deploy.ps1 -bucketName "homefods-yourname-2025"
```

**What this script does:**
1. ✅ Creates S3 bucket
2. ✅ Enables static website hosting
3. ✅ Makes bucket public
4. ✅ Uploads all your files
5. ✅ Creates CloudFront distribution
6. ✅ Configures HTTPS
7. ✅ Waits for deployment

**Time: 15-20 minutes** (mostly waiting for CloudFront)

**After completion, you'll see:**
- ✅ Your S3 website URL
- ✅ Your CloudFront HTTPS URL
- ✅ CloudFront Distribution ID

---

## 🎯 Option 2: Manual Step-by-Step (If you want control)

### Step 1: Create S3 Bucket

```powershell
# Create bucket
aws s3 mb s3://homefods-website-2025 --region us-east-1

# Enable website hosting
aws s3 website s3://homefods-website-2025 --index-document index.html --error-document index.html
```

### Step 2: Make Bucket Public

```powershell
# Remove public access block
aws s3api put-public-access-block `
  --bucket homefods-website-2025 `
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Apply bucket policy
aws s3api put-bucket-policy --bucket homefods-website-2025 --policy file://bucket-policy.json
```

### Step 3: Upload Files

```powershell
# Upload all files
aws s3 sync . s3://homefods-website-2025 `
  --exclude ".git/*" `
  --exclude "node_modules/*" `
  --exclude "*.md" `
  --exclude "*.ps1" `
  --delete

# Set content types for HTML
aws s3 cp s3://homefods-website-2025 s3://homefods-website-2025 --recursive `
  --metadata-directive REPLACE `
  --content-type "text/html" `
  --exclude "*" `
  --include "*.html"

# Set content types for images
aws s3 cp s3://homefods-website-2025 s3://homefods-website-2025 --recursive `
  --metadata-directive REPLACE `
  --content-type "image/jpeg" `
  --exclude "*" `
  --include "*.jpg"
```

### Step 4: Test S3 Website

Open in browser:
```
http://homefods-website-2025.s3-website-us-east-1.amazonaws.com
```

### Step 5: Create CloudFront Distribution

```powershell
# Use the automated script
.\full-deploy.ps1 -bucketName "homefods-website-2025"
# Or create manually via Console (recommended for CloudFront)
```

---

## 🔄 Updating Your Website

After initial deployment, use this script to update:

```powershell
# Update with your saved values
.\update-site.ps1 -bucketName "homefods-website-2025" -cloudfrontId "E1234567890ABC"
```

**This will:**
1. Upload new/changed files
2. Clear CloudFront cache
3. Make updates live in 5-10 minutes

---

## 📋 What You'll Get After Deployment

### URLs
- **S3 Website (HTTP)**: `http://homefods-website-2025.s3-website-us-east-1.amazonaws.com`
- **CloudFront (HTTPS)**: `https://d1234567890abc.cloudfront.net` ⭐ **Use this one!**

### AWS Resources Created
- ✅ S3 Bucket with static website hosting
- ✅ CloudFront Distribution with HTTPS
- ✅ Public access configured
- ✅ All files uploaded and configured

### Configuration File
After deployment, check `aws-config.txt` for all your values:
```
S3_BUCKET=homefods-website-2025
CLOUDFRONT_ID=E1234567890ABC
CLOUDFRONT_DOMAIN=d1234567890abc.cloudfront.net
```

**Save these values!** You'll need them for updates.

---

## 🔥 Firebase Configuration

After deployment completes:

1. Go to Firebase Console: https://console.firebase.google.com
2. Select project: **home-foods-9f024**
3. Go to: **Authentication** → **Settings** → **Authorized Domains**
4. Click **"Add domain"**
5. Add your CloudFront domain (without https://):
   ```
   d1234567890abc.cloudfront.net
   ```
6. Save

---

## ✅ Testing Checklist

After deployment, test these:

- [ ] Homepage loads: `https://your-cloudfront-domain.cloudfront.net`
- [ ] All images display
- [ ] Menu page works
- [ ] Sign up works
- [ ] Sign in works
- [ ] Add to cart works
- [ ] Checkout works
- [ ] Order placement works
- [ ] Admin dashboard accessible
- [ ] HTTPS lock icon shows in browser

---

## 🆘 Troubleshooting

### Error: "Bucket name already exists"
**Solution**: Use a different bucket name
```powershell
.\full-deploy.ps1 -bucketName "homefods-yourname-2025"
```

### Error: "AWS credentials not configured"
**Solution**: Run `aws configure` and enter your credentials

### Error: "Access Denied"
**Solution**: Make sure your AWS user has these permissions:
- S3: Full Access
- CloudFront: Full Access
- IAM: Basic permissions

### Website shows but images don't load
**Solution**: Check content types were set correctly
```powershell
# Re-run content type command
aws s3 cp s3://homefods-website-2025 s3://homefods-website-2025 --recursive `
  --metadata-directive REPLACE `
  --content-type "image/jpeg" `
  --exclude "*" `
  --include "*.jpg"
```

### Firebase login doesn't work
**Solution**: Add CloudFront domain to Firebase authorized domains (see Firebase Configuration section above)

### Updates not showing
**Solution**: Invalidate CloudFront cache
```powershell
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

---

## 💰 Cost Estimate

| Service | Monthly Cost |
|---------|--------------|
| S3 Storage (5GB) | $1-2 |
| S3 Requests | $0.50 |
| CloudFront (50GB) | $5-10 |
| **TOTAL** | **$6-12/month** |

**First year mostly covered by AWS Free Tier!**

---

## 📞 Common Commands Reference

```powershell
# List your S3 buckets
aws s3 ls

# List files in your bucket
aws s3 ls s3://homefods-website-2025 --recursive

# Download a file from S3
aws s3 cp s3://homefods-website-2025/index.html ./index-backup.html

# Delete a file from S3
aws s3 rm s3://homefods-website-2025/old-file.html

# List CloudFront distributions
aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName]" --output table

# Get CloudFront status
aws cloudfront get-distribution --id YOUR_ID --query "Distribution.Status"

# Create cache invalidation
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation --distribution-id YOUR_ID --id INVALIDATION_ID
```

---

## 🎯 Quick Commands Summary

### First Time Deployment:
```powershell
cd C:\Users\ASUS\Desktop\HOMEFODS-main
.\full-deploy.ps1 -bucketName "homefods-website-2025"
```

### Update Website:
```powershell
.\update-site.ps1 -bucketName "homefods-website-2025" -cloudfrontId "E1234567890ABC"
```

### Clear CloudFront Cache:
```powershell
aws cloudfront create-invalidation --distribution-id E1234567890ABC --paths "/*"
```

---

## 🚀 Ready to Deploy?

1. **Open PowerShell**
2. **Navigate to your project:**
   ```powershell
   cd C:\Users\ASUS\Desktop\HOMEFODS-main
   ```
3. **Run deployment:**
   ```powershell
   .\full-deploy.ps1 -bucketName "homefods-website-2025"
   ```
4. **Wait 15-20 minutes**
5. **Test your CloudFront URL**
6. **Add domain to Firebase**
7. **You're live! 🎉**

---

## 📝 Next Steps After Deployment

1. ✅ Test all functionality
2. ✅ Configure custom domain (optional)
3. ✅ Set up billing alerts in AWS
4. ✅ Enable S3 versioning for backup
5. ✅ Set up CloudWatch monitoring

---

**Need help? Let me know which step you're stuck on!** 🚀
