# HOMEFODS - Complete AWS Deployment Plan

## 📋 Project Analysis Summary

### Technology Stack Identified:
- **Frontend**: Pure HTML, CSS (Tailwind CDN), Vanilla JavaScript
- **Backend**: Firebase (Firestore Database, Authentication, Storage)
- **APIs Used**:
  - Firebase API (for database and authentication)
  - EmailJS API (for email notifications)
  - Twilio API (for SMS notifications via backend server)
- **Static Assets**: Images (JPG files)
- **Backend Server**: Node.js/Express (for handling API credentials securely)

### Application Features:
1. User Authentication (Sign In/Sign Up)
2. Product Menu Display (Snacks, Sweets, Pickles, Powders)
3. Shopping Cart System
4. Order Placement
5. Admin Dashboard (Inventory Management, Order Management, Customer Management)
6. Email Notifications (via EmailJS)
7. SMS Notifications (via Twilio)

---

## 🏗️ AWS Architecture Overview

```
Internet
    ↓
CloudFront (CDN) ← SSL Certificate (ACM)
    ↓
S3 Bucket (Static Website Hosting)
    ↓
Firebase Services (Backend)
    ├── Firestore Database
    ├── Authentication
    └── Storage
    
Elastic Beanstalk or EC2 (API Server for credentials)
    ├── Twilio SMS Integration
    └── Secure API Endpoint Management
```

---

## 📦 Required AWS Services (Detailed)

### 1. **Amazon S3** (Primary Hosting - REQUIRED)
**Purpose**: Host all static files (HTML, CSS, JS, Images)

**Configuration**:
- **Bucket Name**: `homefods-website`
- **Region**: `us-east-1` (or your preferred region)
- **Versioning**: Enabled (for rollback capability)
- **Static Website Hosting**: Enabled
- **Index Document**: `index.html`
- **Error Document**: `index.html` (for SPA-like behavior)

**Cost**: ~$0.50-$2/month for storage + $0.40 for requests

**Files to Upload**:
```
- index.html
- menu.html
- signin.html
- signup.html
- ordernow.html
- dashboard.html
- All .jpg image files
- Any CSS/JS files (if separated)
```

---

### 2. **Amazon CloudFront** (CDN - REQUIRED)
**Purpose**: 
- Fast global content delivery
- HTTPS support
- Caching for better performance
- DDoS protection

**Configuration**:
- **Origin**: S3 bucket static website endpoint
- **Price Class**: Use All Edge Locations
- **Alternate Domain Names**: yourdomain.com, www.yourdomain.com
- **SSL Certificate**: From AWS Certificate Manager
- **Default Root Object**: `index.html`
- **Error Pages**: 
  - 403 → /index.html (200)
  - 404 → /index.html (200)

**Cache Behaviors**:
- HTML files: No cache or short TTL (5 minutes)
- Images: Long TTL (1 year)
- CSS/JS: Medium TTL (1 day)

**Cost**: ~$5-10/month for 50GB data transfer + 1M requests

---

### 3. **AWS Certificate Manager (ACM)** (SSL - REQUIRED)
**Purpose**: Free SSL/TLS certificates for HTTPS

**Configuration**:
- **Certificate Type**: Public certificate
- **Domain Names**:
  - yourdomain.com
  - *.yourdomain.com (wildcard)
- **Validation**: DNS validation (via Route 53)
- **Auto-renewal**: Enabled

**Cost**: FREE

---

### 4. **Amazon Route 53** (DNS - REQUIRED)
**Purpose**: Domain name management and routing

**Configuration**:
- **Hosted Zone**: yourdomain.com
- **Record Sets**:
  - **A Record (Alias)**: yourdomain.com → CloudFront Distribution
  - **A Record (Alias)**: www.yourdomain.com → CloudFront Distribution
  - **CNAME**: Validation records for ACM

**Cost**: $0.50/month per hosted zone + $0.40 per million queries

---

### 5. **AWS Elastic Beanstalk** or **EC2** (API Server - REQUIRED)
**Purpose**: Host Node.js backend server for:
- Secure Firebase credentials endpoint
- Secure EmailJS credentials endpoint
- Twilio SMS integration
- API proxy for sensitive operations

**Why Needed**: Your `ordernow.html` fetches credentials from:
```javascript
fetch('https://abhi-red-one.vercel.app/api/credentials/firebase')
fetch('https://abhi-red-one.vercel.app/api/credentials/emailjs')
fetch('https://abhi-red-one.vercel.app/api/send-sms')
```

**Option A: Elastic Beanstalk (RECOMMENDED)**
- **Platform**: Node.js 18 or 20
- **Environment**: Single instance (for cost optimization)
- **Auto-scaling**: Disabled initially
- **Health monitoring**: Basic
- **Load Balancer**: Application Load Balancer (for HTTPS)

**Option B: EC2 Instance**
- **Instance Type**: t2.micro (free tier) or t2.small
- **AMI**: Amazon Linux 2 or Ubuntu 22.04
- **Security Group**:
  - SSH (22): Your IP only
  - HTTP (80): 0.0.0.0/0
  - HTTPS (443): 0.0.0.0/0
  - Custom TCP (3000): 0.0.0.0/0

**Backend Server Requirements**:
```javascript
// server.js structure needed
const express = require('express');
const cors = require('cors');

app.get('/api/credentials/firebase', (req, res) => {
  res.json({
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    // ... other config
  });
});

app.get('/api/credentials/emailjs', (req, res) => {
  res.json({
    EMAIL_PUBLIC_KEY: process.env.EMAILJS_PUBLIC_KEY
  });
});

app.post('/api/send-sms', (req, res) => {
  // Twilio SMS logic
});
```

**Environment Variables to Set**:
```bash
FIREBASE_API_KEY=AIzaSyBrtUADtAu6HcniJlrll41hswuj9gnpKWg
FIREBASE_AUTH_DOMAIN=home-foods-9f024.firebaseapp.com
FIREBASE_PROJECT_ID=home-foods-9f024
FIREBASE_STORAGE_BUCKET=home-foods-9f024.appspot.com
FIREBASE_MESSAGING_SENDER_ID=403437439856
FIREBASE_APP_ID=1:403437439856:web:a95a64fc4242552438ddb5

EMAILJS_PUBLIC_KEY=your-emailjs-public-key
EMAILJS_SERVICE_ID=service_c0g8ern
EMAILJS_TEMPLATE_ID=template_bri376k

TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=your-twilio-number
ADMIN_PHONE_NUMBER=your-admin-phone
```

**Cost (Elastic Beanstalk)**: ~$15-25/month
**Cost (EC2 t2.micro)**: Free tier or ~$8-10/month

---

### 6. **AWS Systems Manager (Parameter Store)** (OPTIONAL but RECOMMENDED)
**Purpose**: Securely store API keys and credentials

**Configuration**:
- Store all environment variables as SecureString type
- Access from EC2/Elastic Beanstalk via IAM role
- No hardcoded credentials in code

**Cost**: FREE for up to 10,000 parameters

---

### 7. **AWS CloudWatch** (Monitoring - RECOMMENDED)
**Purpose**: 
- Monitor application logs
- Track errors and performance
- Set up alarms for issues

**Configuration**:
- **Log Groups**: 
  - `/aws/elasticbeanstalk/application`
  - `/aws/cloudfront/distribution`
- **Alarms**:
  - High error rate (4xx/5xx)
  - High latency
  - Low disk space

**Cost**: ~$1-5/month for basic monitoring

---

### 8. **AWS IAM** (Security - REQUIRED)
**Purpose**: Manage access permissions

**Required Policies**:
- S3 read access for CloudFront
- CloudWatch logs write access for EC2/Beanstalk
- Systems Manager read access for EC2/Beanstalk

**Cost**: FREE

---

## 📊 Total Cost Breakdown

| Service | Configuration | Monthly Cost (USD) |
|---------|--------------|-------------------|
| S3 Storage | 5GB + requests | $1-2 |
| CloudFront | 50GB + 1M requests | $5-10 |
| Route 53 | 1 hosted zone | $0.50 |
| ACM Certificate | SSL certificate | FREE |
| Elastic Beanstalk | Single instance | $15-25 |
| CloudWatch | Basic monitoring | $1-5 |
| Data Transfer | Outbound | $5-10 |
| **TOTAL** | | **$27-52/month** |

**Alternative (Lower Cost)**:
- Use EC2 t2.micro (free tier): **$8-15/month**
- Minimal CloudWatch: **$17-25/month total**

---

## 🚀 Step-by-Step Deployment Guide

### Phase 1: Backend Server Deployment (Elastic Beanstalk)

#### Step 1.1: Create Backend Server Files

**Create `server.js`:**
```javascript
const express = require('express');
const cors = require('cors');
const twilio = require('twilio');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: ['https://yourdomain.com', 'https://www.yourdomain.com'],
  credentials: true
}));
app.use(express.json());

// Firebase credentials endpoint
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

// EmailJS credentials endpoint
app.get('/api/credentials/emailjs', (req, res) => {
  res.json({
    EMAIL_PUBLIC_KEY: process.env.EMAILJS_PUBLIC_KEY
  });
});

// SMS notification endpoint
app.post('/api/send-sms', async (req, res) => {
  try {
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );

    const message = await client.messages.create({
      body: req.body.message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: process.env.ADMIN_PHONE_NUMBER
    });

    res.json({ 
      success: true, 
      messageSid: message.sid 
    });
  } catch (error) {
    console.error('SMS Error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Create `package.json`:**
```json
{
  "name": "homefods-api-server",
  "version": "1.0.0",
  "description": "API server for HOMEFODS application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "twilio": "^4.19.0"
  },
  "engines": {
    "node": "18.x"
  }
}
```

**Create `.ebextensions/environment.config`:**
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    PORT: 8080
```

#### Step 1.2: Deploy to Elastic Beanstalk

**Via AWS Console:**
```bash
1. Go to Elastic Beanstalk Console
2. Create New Application
   - Name: homefods-api
   - Platform: Node.js 18
   - Application code: Upload ZIP (server.js + package.json)

3. Configure Environment
   - Environment name: homefods-api-prod
   - Domain: homefods-api-prod
   - Preset: Single instance (for cost)

4. Configure Environment Variables
   - Add all Firebase, EmailJS, and Twilio credentials

5. Create Application

6. Wait for deployment (5-10 minutes)

7. Note the URL: homefods-api-prod.us-east-1.elasticbeanstalk.com
```

**Via AWS CLI:**
```powershell
# Install EB CLI
pip install awsebcli

# Initialize EB application
eb init -p node.js-18 homefods-api --region us-east-1

# Create environment
eb create homefods-api-prod

# Set environment variables
eb setenv FIREBASE_API_KEY=your-key FIREBASE_AUTH_DOMAIN=your-domain ...

# Deploy
eb deploy

# Open in browser
eb open
```

#### Step 1.3: Configure Custom Domain for API (Optional)

```bash
1. Go to Route 53
2. Create CNAME record:
   - Name: api.yourdomain.com
   - Type: CNAME
   - Value: homefods-api-prod.us-east-1.elasticbeanstalk.com

3. Update Elastic Beanstalk to use custom domain
4. Add SSL certificate via ACM
```

---

### Phase 2: Frontend Deployment (S3 + CloudFront)

#### Step 2.1: Update Frontend Code

**Update `ordernow.html` API endpoints:**
```javascript
// Replace this:
const response = await fetch('https://abhi-red-one.vercel.app/api/credentials/firebase');

// With:
const response = await fetch('https://api.yourdomain.com/api/credentials/firebase');
// OR
const response = await fetch('https://homefods-api-prod.us-east-1.elasticbeanstalk.com/api/credentials/firebase');
```

Do the same for:
- `/api/credentials/emailjs`
- `/api/send-sms`

#### Step 2.2: Create S3 Bucket

**Via AWS Console:**
```bash
1. Go to S3 Console
2. Create Bucket
   - Name: homefods-website (must be globally unique)
   - Region: us-east-1
   - Uncheck "Block all public access"
   - Enable versioning
   - Create bucket

3. Enable Static Website Hosting
   - Go to bucket → Properties → Static website hosting
   - Enable
   - Index document: index.html
   - Error document: index.html
   - Note the endpoint URL

4. Set Bucket Policy (for public read access)
```

**Bucket Policy JSON:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::homefods-website/*"
    }
  ]
}
```

**Via AWS CLI:**
```powershell
# Create bucket
aws s3 mb s3://homefods-website --region us-east-1

# Enable website hosting
aws s3 website s3://homefods-website --index-document index.html --error-document index.html

# Apply bucket policy
aws s3api put-bucket-policy --bucket homefods-website --policy file://bucket-policy.json

# Enable versioning
aws s3api put-bucket-versioning --bucket homefods-website --versioning-configuration Status=Enabled
```

#### Step 2.3: Upload Files to S3

**Via AWS Console:**
```bash
1. Go to S3 bucket
2. Click "Upload"
3. Drag and drop all files:
   - All .html files
   - All .jpg files
4. Click "Upload"
```

**Via AWS CLI (Recommended):**
```powershell
# Navigate to your project folder
cd C:\Users\ASUS\Desktop\HOMEFODS-main

# Sync all files to S3
aws s3 sync . s3://homefods-website `
  --exclude ".git/*" `
  --exclude "node_modules/*" `
  --exclude "*.md" `
  --exclude ".gitignore" `
  --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" `
  --delete

# Set correct content types
aws s3 cp s3://homefods-website s3://homefods-website --recursive --metadata-directive REPLACE --content-type "text/html" --exclude "*" --include "*.html"
aws s3 cp s3://homefods-website s3://homefods-website --recursive --metadata-directive REPLACE --content-type "image/jpeg" --exclude "*" --include "*.jpg"

# Verify upload
aws s3 ls s3://homefods-website --recursive
```

#### Step 2.4: Test S3 Website

```bash
# Get the S3 website URL
http://homefods-website.s3-website-us-east-1.amazonaws.com

# Open in browser and test
```

---

### Phase 3: CloudFront CDN Setup

#### Step 3.1: Create CloudFront Distribution

**Via AWS Console:**
```bash
1. Go to CloudFront Console
2. Create Distribution

3. Origin Settings:
   - Origin Domain: homefods-website.s3-website-us-east-1.amazonaws.com
   - Protocol: HTTP only (S3 website endpoint doesn't support HTTPS)
   - Name: S3-homefods-website

4. Default Cache Behavior:
   - Viewer Protocol Policy: Redirect HTTP to HTTPS
   - Allowed HTTP Methods: GET, HEAD, OPTIONS
   - Cache Policy: CachingOptimized
   - Compress Objects: Yes

5. Settings:
   - Price Class: Use All Edge Locations
   - Alternate Domain Names: 
     * yourdomain.com
     * www.yourdomain.com
   - Custom SSL Certificate: (Select from ACM - create in next step)
   - Default Root Object: index.html

6. Custom Error Pages:
   - 403: Response Page Path: /index.html, Response Code: 200
   - 404: Response Page Path: /index.html, Response Code: 200

7. Create Distribution

8. Note the Distribution Domain Name: d1234567890.cloudfront.net
```

**Via AWS CLI:**
```powershell
# Create distribution (use JSON config file)
aws cloudfront create-distribution --cli-input-json file://cloudfront-config.json

# Get distribution ID
aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text
```

---

### Phase 4: SSL Certificate (ACM)

#### Step 4.1: Request Certificate

**Via AWS Console:**
```bash
1. Go to AWS Certificate Manager (ACM)
   - IMPORTANT: Must be in us-east-1 region for CloudFront

2. Request Certificate
   - Certificate type: Request a public certificate

3. Domain Names:
   - yourdomain.com
   - *.yourdomain.com (wildcard for subdomains)

4. Validation Method: DNS validation

5. Request Certificate

6. Validation:
   - For each domain, ACM will provide CNAME records
   - Add these CNAME records to Route 53

7. Wait for validation (5-30 minutes)

8. Once validated, go back to CloudFront distribution
   - Edit → Custom SSL Certificate
   - Select your certificate
   - Save changes
```

---

### Phase 5: DNS Setup (Route 53)

#### Step 5.1: Create Hosted Zone

**Via AWS Console:**
```bash
1. Go to Route 53 Console
2. Create Hosted Zone
   - Domain name: yourdomain.com
   - Type: Public Hosted Zone
   - Create

3. Note the Name Servers (NS records)
4. Update your domain registrar with these name servers
```

#### Step 5.2: Create DNS Records

```bash
1. Create A Record (Alias) for root domain:
   - Record name: (leave empty)
   - Record type: A
   - Alias: Yes
   - Route traffic to: CloudFront distribution
   - Select your distribution
   - Create record

2. Create A Record (Alias) for www:
   - Record name: www
   - Record type: A
   - Alias: Yes
   - Route traffic to: CloudFront distribution
   - Select your distribution
   - Create record

3. Create CNAME for API subdomain (if using):
   - Record name: api
   - Record type: CNAME
   - Value: homefods-api-prod.us-east-1.elasticbeanstalk.com
   - Create record
```

---

### Phase 6: Firebase Configuration

#### Step 6.1: Verify Firebase Settings

```bash
1. Go to Firebase Console (https://console.firebase.google.com)

2. Select your project: home-foods-9f024

3. Authentication:
   - Enable Email/Password sign-in
   - Enable Google sign-in (if needed)
   - Add authorized domains:
     * yourdomain.com
     * www.yourdomain.com
     * cloudfront-domain.cloudfront.net

4. Firestore Database:
   - Already set up
   - Verify security rules are in place

5. Storage:
   - Add CORS configuration
```

**Storage CORS Configuration:**
```json
[
  {
    "origin": ["https://yourdomain.com", "https://www.yourdomain.com"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

---

### Phase 7: Testing and Validation

#### Step 7.1: Test Checklist

```bash
✅ Backend API Tests:
   - https://api.yourdomain.com/health (should return {"status":"healthy"})
   - https://api.yourdomain.com/api/credentials/firebase (should return config)
   - https://api.yourdomain.com/api/credentials/emailjs (should return key)

✅ Frontend Tests:
   - https://yourdomain.com (homepage loads)
   - https://www.yourdomain.com (www subdomain works)
   - All pages accessible (menu, signin, signup, ordernow, dashboard)

✅ Functionality Tests:
   - User registration works
   - User login works
   - Menu displays products correctly
   - Add to cart works
   - Checkout process works
   - Order submission succeeds
   - Email notification received
   - SMS notification received (admin)
   - Admin dashboard accessible (for admin users)
   - Admin can manage inventory
   - Admin can view orders

✅ Performance Tests:
   - Page load time < 3 seconds
   - Images load quickly (via CloudFront)
   - No console errors
   - Mobile responsive design works

✅ Security Tests:
   - HTTPS working on all pages
   - Firebase rules prevent unauthorized access
   - API credentials not exposed in frontend
   - Admin dashboard only accessible to admins
```

---

## 🔒 Security Best Practices

### 1. Never Commit Sensitive Data
```bash
# Add to .gitignore:
home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json
.env
*.pem
*.key
node_modules/
```

### 2. Use Environment Variables
```bash
# Never hardcode credentials in code
# Always use process.env.VARIABLE_NAME
```

### 3. Implement Rate Limiting
```javascript
// In server.js
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 4. Enable CORS Properly
```javascript
// Only allow your domain
app.use(cors({
  origin: ['https://yourdomain.com'],
  credentials: true
}));
```

### 5. Firebase Security Rules
```javascript
// Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    
    match /items/{category}/products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 📝 Deployment Scripts

### **PowerShell Deployment Script** (`deploy.ps1`)

```powershell
# HOMEFODS AWS Deployment Script
# Run this from your project root directory

param(
    [string]$environment = "production"
)

Write-Host "=== HOMEFODS Deployment Script ===" -ForegroundColor Green
Write-Host "Environment: $environment" -ForegroundColor Cyan

# Configuration
$S3_BUCKET = "homefods-website"
$CLOUDFRONT_ID = "YOUR_DISTRIBUTION_ID"  # Replace with actual ID
$AWS_REGION = "us-east-1"

# Step 1: Build (if needed)
Write-Host "`n[1/4] Building project..." -ForegroundColor Yellow
# Add any build steps here if needed

# Step 2: Upload to S3
Write-Host "`n[2/4] Uploading files to S3..." -ForegroundColor Yellow
aws s3 sync . s3://$S3_BUCKET `
  --exclude ".git/*" `
  --exclude "node_modules/*" `
  --exclude "*.md" `
  --exclude ".gitignore" `
  --exclude "*.ps1" `
  --exclude "home-foods-9f024-firebase-adminsdk-fbsvc-003646254a.json" `
  --delete `
  --region $AWS_REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ S3 upload failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Set correct content types
Write-Host "`n[3/4] Setting content types..." -ForegroundColor Yellow
aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET --recursive `
  --metadata-directive REPLACE `
  --content-type "text/html" `
  --exclude "*" `
  --include "*.html"

aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET --recursive `
  --metadata-directive REPLACE `
  --content-type "image/jpeg" `
  --exclude "*" `
  --include "*.jpg"

# Step 4: Invalidate CloudFront cache
Write-Host "`n[4/4] Invalidating CloudFront cache..." -ForegroundColor Yellow
aws cloudfront create-invalidation `
  --distribution-id $CLOUDFRONT_ID `
  --paths "/*"

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "Your site is live at: https://yourdomain.com" -ForegroundColor Cyan
```

**Usage:**
```powershell
# Make sure AWS CLI is configured
aws configure

# Run deployment
.\deploy.ps1

# Or specify environment
.\deploy.ps1 -environment staging
```

---

## 🔄 CI/CD Pipeline (Optional - GitHub Actions)

### `.github/workflows/deploy.yml`

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  S3_BUCKET: homefods-website
  CLOUDFRONT_ID: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Upload to S3
      run: |
        aws s3 sync . s3://${{ env.S3_BUCKET }} \
          --exclude ".git/*" \
          --exclude "node_modules/*" \
          --exclude "*.md" \
          --delete

    - name: Set content types
      run: |
        aws s3 cp s3://${{ env.S3_BUCKET }} s3://${{ env.S3_BUCKET }} --recursive \
          --metadata-directive REPLACE \
          --content-type "text/html" \
          --exclude "*" \
          --include "*.html"

    - name: Invalidate CloudFront
      run: |
        aws cloudfront create-invalidation \
          --distribution-id ${{ env.CLOUDFRONT_ID }} \
          --paths "/*"

    - name: Deployment complete
      run: echo "✅ Deployment successful!"
```

---

## 📊 Monitoring and Maintenance

### CloudWatch Alarms to Set Up:

```bash
1. High Error Rate Alarm:
   - Metric: 4xxErrorRate or 5xxErrorRate
   - Threshold: > 5%
   - Action: SNS notification

2. High Latency Alarm:
   - Metric: OriginLatency
   - Threshold: > 1000ms
   - Action: SNS notification

3. Low Requests Alarm:
   - Metric: Requests
   - Threshold: < 10 requests/hour
   - Action: SNS notification (potential downtime)
```

### Regular Maintenance Tasks:

```bash
✅ Weekly:
   - Check CloudWatch logs for errors
   - Review Firebase usage
   - Monitor AWS billing

✅ Monthly:
   - Review and optimize CloudFront cache settings
   - Update dependencies (npm update)
   - Review security group rules
   - Check SSL certificate expiration

✅ Quarterly:
   - Review Firebase security rules
   - Perform security audit
   - Optimize S3 storage costs
   - Review and update documentation
```

---

## 🚨 Troubleshooting Guide

### Issue 1: "Firebase API key exposed" warning
**Solution**: This is expected. Firebase API keys are meant to be public. Security is handled by Firebase rules.

### Issue 2: CORS errors
**Solution**: 
- Check backend server CORS configuration
- Add your domain to Firebase authorized domains
- Verify S3 bucket CORS configuration

### Issue 3: CloudFront not serving latest content
**Solution**:
```bash
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

### Issue 4: SMS not sending
**Solution**:
- Verify Twilio credentials in environment variables
- Check Twilio account balance
- Verify phone number format (+91XXXXXXXXXX)

### Issue 5: Email notifications failing
**Solution**:
- Verify EmailJS service is active
- Check EmailJS template ID
- Verify email quota not exceeded

---

## 📈 Scaling Recommendations

### When you grow:

**Stage 1: Current Setup (0-1000 users)**
- S3 + CloudFront + Single Elastic Beanstalk instance
- Cost: ~$30-50/month

**Stage 2: Growing (1000-10,000 users)**
- Enable Elastic Beanstalk auto-scaling
- Add Application Load Balancer
- Use RDS for additional data storage
- Cost: ~$100-200/month

**Stage 3: Scaling (10,000+ users)**
- Multi-AZ deployment
- ElastiCache for session management
- Separate database (RDS or DynamoDB)
- CloudFront with more edge locations
- Cost: ~$500+/month

---

## 🎯 Next Steps After Deployment

1. **Set up monitoring alerts**
2. **Configure automated backups**
3. **Set up staging environment**
4. **Implement A/B testing**
5. **Add analytics (Google Analytics)**
6. **Implement feedback system**
7. **Set up error tracking (Sentry)**
8. **Create mobile app (React Native/Flutter)**

---

## 📞 Support and Resources

### AWS Documentation:
- S3: https://docs.aws.amazon.com/s3/
- CloudFront: https://docs.aws.amazon.com/cloudfront/
- Elastic Beanstalk: https://docs.aws.amazon.com/elasticbeanstalk/
- Route 53: https://docs.aws.amazon.com/route53/

### Firebase Documentation:
- https://firebase.google.com/docs

### EmailJS Documentation:
- https://www.emailjs.com/docs/

### Twilio Documentation:
- https://www.twilio.com/docs/

---

**Deployment Timeline**: 4-6 hours (first time), 30 minutes (subsequent deploys)

**Estimated Total Cost**: $30-50/month for production deployment

This deployment plan provides a production-ready, scalable, and secure infrastructure for your HOMEFODS application on AWS! 🚀
