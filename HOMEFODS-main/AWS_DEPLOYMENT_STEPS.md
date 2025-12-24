# HOMEFODS - Step-by-Step AWS Deployment Guide
## (Moving from GitHub Pages to AWS)

---

## ✅ Prerequisites Checklist

Before starting, make sure you have:

- [ ] AWS Account created (https://aws.amazon.com)
- [ ] Credit/Debit card added to AWS account
- [ ] Your domain name (or you can use CloudFront URL initially)
- [ ] All Firebase credentials ready
- [ ] Your project files (already on GitHub)

---

## 📦 **STEP 1: Set Up AWS CLI** (15 minutes)

### 1.1 Download and Install AWS CLI

**For Windows:**
```powershell
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
# Run the installer
# Restart PowerShell after installation
```

**Verify installation:**
```powershell
aws --version
# Should show: aws-cli/2.x.x
```

### 1.2 Create AWS Access Keys

1. **Go to AWS Console**: https://console.aws.amazon.com
2. **Click your name (top right)** → Security Credentials
3. **Scroll to "Access keys"** → Click "Create access key"
4. **Select use case**: "Command Line Interface (CLI)"
5. **Check the confirmation box** → Next
6. **Add description**: "HOMEFODS CLI Access"
7. **Create access key**
8. **IMPORTANT**: Download the .csv file or copy both:
   - Access Key ID: `AKIAXXXXXXXXXXXXXXXX`
   - Secret Access Key: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 1.3 Configure AWS CLI

```powershell
# Run this command
aws configure

# Enter when prompted:
AWS Access Key ID [None]: AKIAXXXXXXXXXXXXXXXX
AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Default region name [None]: us-east-1
Default output format [None]: json
```

**Test the configuration:**
```powershell
aws s3 ls
# Should not show any errors (might show empty list)
```

✅ **CHECKPOINT**: AWS CLI is configured

---

## 📦 **STEP 2: Create S3 Bucket for Website Hosting** (10 minutes)

### 2.1 Create the S3 Bucket

```powershell
# Navigate to your project folder
cd C:\Users\ASUS\Desktop\HOMEFODS-main

# Create bucket (name must be globally unique - use your own name)
aws s3 mb s3://homefods-website-2025 --region us-east-1

# You should see: make_bucket: homefods-website-2025
```

**If you get "Bucket name already exists" error:**
```powershell
# Try with a unique name
aws s3 mb s3://homefods-yourname-website --region us-east-1
# Or: aws s3 mb s3://homefods-123456 --region us-east-1
```

### 2.2 Enable Static Website Hosting

```powershell
# Enable website hosting
aws s3 website s3://homefods-website-2025 --index-document index.html --error-document index.html
```

### 2.3 Make Bucket Public

**Create a file named `bucket-policy.json` in your project folder:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::homefods-website-2025/*"
    }
  ]
}
```

**Apply the policy:**
```powershell
# First, remove public access block
aws s3api put-public-access-block --bucket homefods-website-2025 --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Apply bucket policy
aws s3api put-bucket-policy --bucket homefods-website-2025 --policy file://bucket-policy.json
```

✅ **CHECKPOINT**: S3 bucket created and configured

---

## 📦 **STEP 3: Upload Your Website Files to S3** (5 minutes)

### 3.1 Upload All Files

```powershell
# Make sure you're in your project directory
cd C:\Users\ASUS\Desktop\HOMEFODS-main

# Upload everything to S3
aws s3 sync . s3://homefods-website-2025 --exclude ".git/*" --exclude "node_modules/*" --exclude "*.md" --exclude ".gitignore" --delete

# You should see all files being uploaded
```

### 3.2 Set Correct Content Types

```powershell
# Set HTML content type
aws s3 cp s3://homefods-website-2025 s3://homefods-website-2025 --recursive --metadata-directive REPLACE --content-type "text/html" --exclude "*" --include "*.html"

# Set image content type
aws s3 cp s3://homefods-website-2025 s3://homefods-website-2025 --recursive --metadata-directive REPLACE --content-type "image/jpeg" --exclude "*" --include "*.jpg"
```

### 3.3 Test Your S3 Website

```powershell
# Get your S3 website URL
echo "Your website is at: http://homefods-website-2025.s3-website-us-east-1.amazonaws.com"
```

**Open this URL in your browser and test:**
- Homepage loads ✓
- Images display ✓
- Menu page works ✓
- Sign in/Sign up pages load ✓

✅ **CHECKPOINT**: Website is live on S3 (HTTP only, no custom domain yet)

---

## 📦 **STEP 4: Set Up CloudFront for HTTPS and Speed** (20 minutes)

### 4.1 Create CloudFront Distribution via Console

1. **Go to CloudFront Console**: https://console.aws.amazon.com/cloudfront/

2. **Click "Create Distribution"**

3. **Origin Settings:**
   - **Origin Domain**: Click the field and DO NOT select the dropdown
   - **Instead, manually type**: `homefods-website-2025.s3-website-us-east-1.amazonaws.com`
   - **Protocol**: HTTP only
   - **Name**: Leave as default

4. **Default Cache Behavior:**
   - **Viewer Protocol Policy**: Redirect HTTP to HTTPS
   - **Allowed HTTP Methods**: GET, HEAD, OPTIONS
   - **Cache Policy**: CachingOptimized

5. **Settings:**
   - **Price Class**: Use All Edge Locations (best performance)
   - **Alternate Domain Names (CNAMEs)**: Leave empty for now
   - **Default Root Object**: `index.html`

6. **Custom Error Pages** - Click "Add custom error response" twice:
   
   **Error Response 1:**
   - HTTP Error Code: 403
   - Customize Error Response: Yes
   - Response Page Path: `/index.html`
   - HTTP Response Code: 200
   
   **Error Response 2:**
   - HTTP Error Code: 404
   - Customize Error Response: Yes
   - Response Page Path: `/index.html`
   - HTTP Response Code: 200

7. **Click "Create Distribution"**

8. **Wait 5-15 minutes** for deployment (Status will change from "Deploying" to "Enabled")

### 4.2 Get Your CloudFront URL

Once deployed, you'll see:
- **Distribution Domain Name**: `d1234567890abc.cloudfront.net`

**Test your CloudFront URL:**
```
https://d1234567890abc.cloudfront.net
```

✅ **CHECKPOINT**: Website is now on HTTPS via CloudFront

---

## 📦 **STEP 5: Configure Custom Domain (Optional but Recommended)** (30 minutes)

### 5.1 Request SSL Certificate (Must do FIRST)

**IMPORTANT: Switch to us-east-1 region for this step**

1. **Go to AWS Certificate Manager**: https://console.aws.amazon.com/acm/
2. **Make sure you're in us-east-1 region** (top right, next to your name)
3. **Click "Request a certificate"**
4. **Select**: Request a public certificate → Next
5. **Domain names**:
   - Add: `yourdomain.com`
   - Click "Add another name"
   - Add: `www.yourdomain.com`
6. **Validation method**: DNS validation
7. **Click "Request"**

### 5.2 Validate Your Domain

1. **Click on your certificate** (it will show "Pending validation")
2. **For each domain**, you'll see CNAME records:
   ```
   Name: _abc123def.yourdomain.com
   Value: _xyz789uvw.acm-validations.aws.
   ```
3. **Add these CNAME records to your domain registrar** (GoDaddy, Namecheap, etc.)
4. **Wait 5-30 minutes** for validation

### 5.3 Add Domain to CloudFront

1. **Go back to CloudFront Console**
2. **Select your distribution**
3. **Click "Edit"**
4. **Alternate Domain Names (CNAMEs)**:
   - Add: `yourdomain.com`
   - Add: `www.yourdomain.com`
5. **Custom SSL Certificate**: Select your certificate from the dropdown
6. **Save changes**

### 5.4 Set Up DNS (Route 53 or Your Domain Registrar)

**Option A: Using Route 53 (Recommended)**

1. **Go to Route 53**: https://console.aws.amazon.com/route53/
2. **Create Hosted Zone**:
   - Domain name: `yourdomain.com`
   - Type: Public Hosted Zone
   - Create
3. **Note the 4 Name Servers** (NS records)
4. **Update your domain registrar** with these name servers
5. **Create A Record (Alias)**:
   - Record name: (leave empty)
   - Record type: A
   - Alias: Yes
   - Route traffic to: CloudFront distribution
   - Select your distribution
   - Create record
6. **Create another A Record for www**:
   - Record name: www
   - Record type: A
   - Alias: Yes
   - Route traffic to: CloudFront distribution
   - Select your distribution
   - Create record

**Option B: Using Your Domain Registrar**

1. Go to your domain registrar (GoDaddy, Namecheap, etc.)
2. Find DNS settings
3. Create CNAME record:
   - Name: www
   - Value: `d1234567890abc.cloudfront.net`
4. Create ALIAS or ANAME record (if supported):
   - Name: @
   - Value: `d1234567890abc.cloudfront.net`

✅ **CHECKPOINT**: Custom domain configured

---

## 📦 **STEP 6: Update Firebase Authorized Domains** (5 minutes)

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select your project**: home-foods-9f024
3. **Go to Authentication** → Settings → Authorized Domains
4. **Add your domains**:
   - `yourdomain.com`
   - `www.yourdomain.com`
   - `d1234567890abc.cloudfront.net` (your CloudFront domain)
5. **Save**

✅ **CHECKPOINT**: Firebase configured for your domain

---

## 📦 **STEP 7: Backend API Server (For SMS & Secure Credentials)** 

### Option 1: Keep Using Vercel (Simplest)

**Your current setup with Vercel is working fine!** 

Just update the authorized origins in your Vercel backend to include:
- `https://yourdomain.com`
- `https://www.yourdomain.com`
- `https://d1234567890abc.cloudfront.net`

✅ **CHECKPOINT**: No changes needed if using Vercel

---

### Option 2: Move to AWS Elastic Beanstalk (Optional)

**Only do this if you want everything on AWS**

#### 7.1 Create Backend Server Files

Create `api-server/server.js`:
```javascript
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors({
  origin: [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
    'https://d1234567890abc.cloudfront.net'
  ]
}));
app.use(express.json());

app.get('/api/credentials/firebase', (req, res) => {
  res.json({
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID,
    measurementId: process.env.FIREBASE_MEASUREMENT_ID
  });
});

app.get('/api/credentials/emailjs', (req, res) => {
  res.json({
    EMAIL_PUBLIC_KEY: process.env.EMAILJS_PUBLIC_KEY
  });
});

app.post('/api/send-sms', async (req, res) => {
  // Add Twilio SMS logic here
  res.json({ success: true });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

Create `api-server/package.json`:
```json
{
  "name": "homefods-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "engines": {
    "node": "18.x"
  }
}
```

#### 7.2 Deploy to Elastic Beanstalk

```powershell
# Install EB CLI
pip install awsebcli

# Navigate to api-server folder
cd api-server

# Initialize
eb init -p node.js-18 homefods-api --region us-east-1

# Create environment and deploy
eb create homefods-api-prod

# Set environment variables
eb setenv FIREBASE_API_KEY=AIzaSyBrtUADtAu6HcniJlrll41hswuj9gnpKWg FIREBASE_AUTH_DOMAIN=home-foods-9f024.firebaseapp.com FIREBASE_PROJECT_ID=home-foods-9f024 FIREBASE_STORAGE_BUCKET=home-foods-9f024.appspot.com FIREBASE_MESSAGING_SENDER_ID=403437439856 FIREBASE_APP_ID=1:403437439856:web:a95a64fc4242552438ddb5 EMAILJS_PUBLIC_KEY=your-key

# Get URL
eb status
```

#### 7.3 Update ordernow.html

Replace Vercel URLs with your Elastic Beanstalk URL:
```javascript
// Change from:
fetch('https://abhi-red-one.vercel.app/api/credentials/firebase')

// To:
fetch('https://homefods-api-prod.us-east-1.elasticbeanstalk.com/api/credentials/firebase')
```

---

## 📦 **STEP 8: Test Everything** (15 minutes)

### 8.1 Functionality Checklist

Open your website: `https://yourdomain.com` (or CloudFront URL)

**Test these features:**

✅ Homepage loads with all images
✅ Menu page displays all products
✅ Click "Add to Cart" - works
✅ Cart icon shows item count
✅ Sign Up - create new account
✅ Sign In - log in with account
✅ Signed-in user can add items to cart
✅ Checkout page loads
✅ Place an order
✅ Check Firebase - order appears in database
✅ Admin login works
✅ Admin dashboard shows orders
✅ Admin can update order status

### 8.2 Performance Check

```
https://pagespeed.web.dev/
```
Enter your URL and check:
- Desktop score > 90
- Mobile score > 80

---

## 📦 **STEP 9: Future Updates (Deployment Script)** 

### Create `deploy.ps1` in your project root:

```powershell
# HOMEFODS Deployment Script
param([string]$message = "Update")

Write-Host "Deploying HOMEFODS to AWS..." -ForegroundColor Green

# Configuration
$S3_BUCKET = "homefods-website-2025"
$CLOUDFRONT_ID = "YOUR_DISTRIBUTION_ID"  # Get from CloudFront console

# Upload to S3
Write-Host "Uploading files..." -ForegroundColor Yellow
aws s3 sync . s3://$S3_BUCKET `
  --exclude ".git/*" `
  --exclude "node_modules/*" `
  --exclude "*.md" `
  --exclude "*.ps1" `
  --delete

# Set content types
aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET --recursive `
  --metadata-directive REPLACE `
  --content-type "text/html" `
  --exclude "*" --include "*.html"

# Invalidate CloudFront cache
Write-Host "Clearing CDN cache..." -ForegroundColor Yellow
aws cloudfront create-invalidation `
  --distribution-id $CLOUDFRONT_ID `
  --paths "/*"

Write-Host "✅ Deployment complete!" -ForegroundColor Green
```

**Usage:**
```powershell
# After making changes, deploy with:
.\deploy.ps1
```

---

## 📊 **Cost Summary**

| Service | What It Does | Monthly Cost |
|---------|-------------|--------------|
| S3 | Stores your files | $1-2 |
| CloudFront | Fast delivery worldwide | $5-10 |
| Route 53 | Custom domain | $0.50 |
| Certificate Manager | Free SSL | FREE |
| Elastic Beanstalk (optional) | Backend API | $15-25 |
| **Total (without backend)** | | **$6-12/month** |
| **Total (with backend)** | | **$21-37/month** |

---

## 🎯 **What You've Accomplished**

✅ Your website is now on AWS infrastructure
✅ Fast loading with CloudFront CDN
✅ Secure HTTPS connection
✅ Custom domain (optional)
✅ Scalable to handle more traffic
✅ Professional production setup

---

## 🆘 **Troubleshooting**

### Issue: "AccessDenied" when accessing S3 URL
**Solution**: Make sure bucket policy is applied correctly

### Issue: CloudFront shows old content
**Solution**: Create cache invalidation:
```powershell
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

### Issue: Firebase authentication not working
**Solution**: Add your domain to Firebase authorized domains

### Issue: Images not loading
**Solution**: Check content-type is set to image/jpeg

### Issue: CORS errors
**Solution**: Check Firebase authorized domains and backend CORS settings

---

## 📞 **Need Help?**

- **AWS Documentation**: https://docs.aws.amazon.com
- **AWS Free Tier**: https://aws.amazon.com/free/
- **Firebase Console**: https://console.firebase.google.com
- **CloudFront Pricing**: https://aws.amazon.com/cloudfront/pricing/

---

## 🚀 **Next Steps**

1. Set up AWS Billing Alerts (to avoid surprises)
2. Enable S3 versioning (for backup)
3. Set up CloudWatch monitoring
4. Create staging environment
5. Implement CI/CD with GitHub Actions

---

**You're all set! Your HOMEFODS website is now running on AWS!** 🎉
