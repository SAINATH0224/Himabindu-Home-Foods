# HOMEFODS - AWS Deployment Guide (Console Only - No CLI)
## Step-by-Step with Screenshots Instructions

---

## 🎯 **What You'll Do (Overview)**

1. ✅ Create S3 Bucket (to store your files)
2. ✅ Upload all your website files to S3
3. ✅ Make S3 bucket public (so people can see your site)
4. ✅ Enable Static Website Hosting
5. ✅ Create CloudFront Distribution (for HTTPS)
6. ✅ Test your website

**Total Time: 45-60 minutes**
**Cost: ~$6-12/month**
**No coding or command line needed!**

---

## 📦 **STEP 1: Create S3 Bucket** (10 minutes)

### 1.1 Go to S3 Service

1. **Log into AWS Console**: https://console.aws.amazon.com
2. In the **search bar at the top**, type: `S3`
3. Click on **"S3"** (it says "Scalable storage in the cloud")

### 1.2 Create New Bucket

1. Click the **"Create bucket"** button (orange button on the right)

2. **Bucket name**: 
   - Type: `homefods-website-2025`
   - ⚠️ If it says "Bucket name already exists", try:
     - `homefods-yourname-2025`
     - `homefods-food-delivery-2025`
     - `homefods-12345` (any unique name)
   - ✅ When you see a green checkmark, the name is available!

3. **AWS Region**: 
   - Select: **US East (N. Virginia) us-east-1**

4. **Object Ownership**: 
   - Keep the default: **"ACLs disabled"**

5. **Block Public Access settings**:
   - ⚠️ **UNCHECK** the box that says **"Block all public access"**
   - A warning will appear in orange
   - ✅ **CHECK** the acknowledgment box below it that says:
     *"I acknowledge that the current settings might result in this bucket and the objects within becoming public"*

6. **Bucket Versioning**: 
   - Leave as **"Disable"**

7. **Tags**: 
   - Skip this (leave empty)

8. **Default encryption**: 
   - Leave as default (Server-side encryption with Amazon S3 managed keys)

9. **Advanced settings**: 
   - Leave as default

10. Click the **"Create bucket"** button at the bottom

✅ **SUCCESS**: You should see your bucket in the list!

---

## 📦 **STEP 2: Enable Static Website Hosting** (5 minutes)

### 2.1 Configure Bucket for Website

1. Click on your **bucket name** (`homefods-website-2025`) from the list

2. Click on the **"Properties"** tab (top of the page)

3. Scroll all the way down to **"Static website hosting"** (last section)

4. Click **"Edit"**

5. **Static website hosting**: Select **"Enable"**

6. **Hosting type**: Select **"Host a static website"**

7. **Index document**: Type `index.html`

8. **Error document**: Type `index.html`

9. Click **"Save changes"** at the bottom

10. **Scroll down again** to "Static website hosting" section
    - You'll see: **Bucket website endpoint**
    - It looks like: `http://homefods-website-2025.s3-website-us-east-1.amazonaws.com`
    - ✅ **COPY THIS URL** - you'll test it later!

---

## 📦 **STEP 3: Make Bucket Public** (5 minutes)

### 3.1 Add Bucket Policy

1. Click on the **"Permissions"** tab (top of the page)

2. Scroll down to **"Bucket policy"** section

3. Click **"Edit"**

4. **Copy and paste** this code into the text box:

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

⚠️ **IMPORTANT**: Replace `homefods-website-2025` with YOUR actual bucket name!

5. Click **"Save changes"**

✅ You should see: **"Publicly accessible"** label on your bucket now

---

## 📦 **STEP 4: Upload Your Website Files** (10 minutes)

### 4.1 Upload Files

1. Click on the **"Objects"** tab (top of the page)

2. Click **"Upload"** button (orange button)

3. Click **"Add files"** button

4. **Navigate to your project folder**:
   - Go to: `C:\Users\ASUS\Desktop\HOMEFODS-main`

5. **Select ALL these files** (hold Ctrl and click each):
   - `index.html`
   - `menu.html`
   - `signin.html`
   - `signup.html`
   - `ordernow.html`
   - `dashboard.html`
   - All `.jpg` files (all your images)

6. Click **"Open"**

7. You should see all files listed in the upload window

8. Scroll down and click **"Upload"** (orange button at bottom)

9. Wait for upload to complete (you'll see "Upload succeeded")

10. Click **"Close"** in the top right

✅ **SUCCESS**: You should see all your files listed in the Objects tab!

---

## 📦 **STEP 5: Test Your S3 Website** (2 minutes)

### 5.1 Access Your Website

1. Remember the URL you copied earlier? It looks like:
   ```
   http://homefods-website-2025.s3-website-us-east-1.amazonaws.com
   ```

2. **Open this URL in your browser**

3. **You should see**:
   - ✅ Your homepage loads
   - ✅ Images display
   - ✅ You can click on Menu, Sign In, etc.

⚠️ **If you see "404 Not Found"**:
- Go back to S3 bucket
- Make sure `index.html` is uploaded
- Check that Static Website Hosting is enabled

⚠️ **If you see "403 Forbidden"**:
- Go back to bucket Permissions
- Make sure Bucket Policy is added correctly
- Make sure "Block all public access" is OFF

✅ **IF IT WORKS**: Your website is now live (but only HTTP, not HTTPS yet)!

---

## 📦 **STEP 6: Create CloudFront Distribution** (15 minutes)

### 6.1 Go to CloudFront

1. In the **search bar at the top**, type: `CloudFront`

2. Click on **"CloudFront"** (says "Global content delivery network")

3. Click **"Create distribution"** button (orange button)

### 6.2 Configure Origin

1. **Origin domain**:
   - Click the input field
   - ⚠️ **DO NOT** select from the dropdown that appears
   - Instead, **type manually** (copy-paste your S3 website endpoint):
     ```
     homefods-website-2025.s3-website-us-east-1.amazonaws.com
     ```
   - Replace with YOUR bucket name!
   - ✅ Make sure it ends with `.amazonaws.com` NOT `.com/`

2. **Protocol**: Select **"HTTP only"**

3. **Name**: Leave as auto-filled

4. Leave all other Origin settings as default

### 6.3 Configure Default Cache Behavior

Scroll down to **"Default cache behavior"** section:

1. **Path pattern**: Leave as `Default (*)`

2. **Compress objects automatically**: Leave as **Yes**

3. **Viewer protocol policy**: Select **"Redirect HTTP to HTTPS"**

4. **Allowed HTTP methods**: Select **"GET, HEAD, OPTIONS"**

5. **Cache policy and origin request policy**:
   - **Cache policy**: Select **"CachingOptimized"**

6. Leave all other settings as default

### 6.4 Configure Settings

Scroll down to **"Settings"** section:

1. **Price class**: Select **"Use all edge locations (best performance)"**

2. **Alternate domain names (CNAMEs)**: Leave empty for now

3. **Custom SSL certificate**: Leave as **"Default CloudFront Certificate (*.cloudfront.net)"**

4. **Default root object**: Type `index.html`

5. **Standard logging**: Leave as **Off**

6. Leave all other settings as default

### 6.5 Add Custom Error Responses

Scroll down to **"Custom error responses"** section:

1. Click **"Create custom error response"** button

   **First Error Response**:
   - **HTTP error code**: Select **403: Forbidden**
   - **Customize error response**: Select **Yes**
   - **Response page path**: Type `/index.html`
   - **HTTP response code**: Select **200: OK**
   - Click **"Create custom error response"**

2. Click **"Create custom error response"** button again

   **Second Error Response**:
   - **HTTP error code**: Select **404: Not Found**
   - **Customize error response**: Select **Yes**
   - **Response page path**: Type `/index.html`
   - **HTTP response code**: Select **200: OK**
   - Click **"Create custom error response"**

### 6.6 Create Distribution

1. Scroll to the bottom

2. Click **"Create distribution"** (orange button)

3. ⏳ **WAIT 5-15 MINUTES** for deployment
   - Status will show **"Deploying"** (spinning icon)
   - Refresh the page every few minutes
   - When ready, status changes to **"Enabled"** with a green dot

4. **While waiting**, you'll see:
   - **Distribution domain name**: Something like `d1234567890abc.cloudfront.net`
   - ✅ **COPY THIS URL** - this is your HTTPS website!

---

## 📦 **STEP 7: Test Your CloudFront Website** (5 minutes)

### 7.1 Access via HTTPS

1. Take your CloudFront domain name (from previous step)
   ```
   d1234567890abc.cloudfront.net
   ```

2. Add `https://` in front:
   ```
   https://d1234567890abc.cloudfront.net
   ```

3. **Open this URL in your browser**

4. **Test everything**:
   - ✅ Homepage loads with images
   - ✅ Menu page works
   - ✅ Sign up page works
   - ✅ Sign in page works
   - ✅ HTTPS lock icon in browser (secure)
   - ✅ Pages load fast

✅ **SUCCESS**: Your website is now live on AWS with HTTPS!

---

## 📦 **STEP 8: Update Firebase Authorized Domains** (5 minutes)

### 8.1 Add CloudFront Domain to Firebase

1. Go to **Firebase Console**: https://console.firebase.google.com

2. Select your project: **home-foods-9f024**

3. Click **⚙️ Settings icon** (left sidebar, bottom) → **Project settings**

4. Click **"Authentication"** tab (top)

5. Scroll down to **"Authorized domains"**

6. Click **"Add domain"**

7. Paste your CloudFront domain (WITHOUT https://):
   ```
   d1234567890abc.cloudfront.net
   ```

8. Click **"Add"**

✅ **SUCCESS**: Firebase will now work with your CloudFront URL!

---

## 🎉 **CONGRATULATIONS! YOU'RE DONE!**

### Your Website URLs:

**S3 Website (HTTP only):**
```
http://homefods-website-2025.s3-website-us-east-1.amazonaws.com
```

**CloudFront (HTTPS - Use this one!):**
```
https://d1234567890abc.cloudfront.net
```

---

## 🔄 **How to Update Your Website in the Future**

When you make changes to your website:

### Update Process:

1. Go to **S3 Console**
2. Click on your bucket: `homefods-website-2025`
3. Click **"Upload"**
4. Select the **files you changed**
5. Click **"Upload"**
6. **IMPORTANT**: Clear CloudFront cache:
   - Go to **CloudFront Console**
   - Select your distribution
   - Click **"Invalidations"** tab
   - Click **"Create invalidation"**
   - In "Object paths", type: `/*`
   - Click **"Create invalidation"**
   - Wait 5 minutes for cache to clear

---

## 💰 **Monthly Cost Breakdown**

| Service | What It Does | Cost |
|---------|-------------|------|
| S3 Storage | Stores your files | $1-2 |
| S3 Requests | File downloads | $0.50 |
| CloudFront | Fast delivery worldwide + HTTPS | $5-10 |
| **TOTAL** | | **$6-12/month** |

**First Year**: Mostly covered by AWS Free Tier!

---

## ❌ **Troubleshooting**

### Problem: "Access Denied" or "403 Forbidden"

**Solution**:
1. Go to S3 → Your bucket → Permissions
2. Check that "Block all public access" is OFF
3. Check that Bucket Policy is added correctly
4. Make sure the bucket policy has YOUR bucket name

### Problem: Website shows but images don't load

**Solution**:
1. Go to S3 → Your bucket → Objects
2. Make sure all `.jpg` files are uploaded
3. Click on an image file
4. Check that "Object URL" works

### Problem: Firebase login doesn't work

**Solution**:
1. Go to Firebase Console → Authentication → Settings
2. Make sure your CloudFront domain is in "Authorized domains"
3. Make sure Firebase config in your HTML files is correct

### Problem: Changes don't appear on website

**Solution**:
1. Go to CloudFront Console
2. Select your distribution
3. Click "Invalidations" → "Create invalidation"
4. Type `/*` → Create
5. Wait 5 minutes

---

## 🚀 **Optional: Add Custom Domain**

If you want to use your own domain (like `homefods.com`):

### Prerequisites:
- You must own a domain (buy from GoDaddy, Namecheap, etc.)
- Cost: $10-15/year for domain

### Steps:
1. Request SSL Certificate in AWS Certificate Manager
2. Validate via DNS
3. Update CloudFront to use your domain
4. Add DNS records at your domain registrar

**Need help with this?** Let me know and I'll create a detailed guide!

---

## 📞 **Need Help?**

If you get stuck at any step:
1. **Take a screenshot** of the error
2. **Note which step** you're on
3. **Tell me** what happened

I'll help you fix it! 🛠️

---

## ✅ **Checklist - Did You Complete Everything?**

- [ ] Created S3 bucket
- [ ] Enabled static website hosting
- [ ] Made bucket public (added bucket policy)
- [ ] Uploaded all website files
- [ ] Tested S3 website URL (HTTP)
- [ ] Created CloudFront distribution
- [ ] Waited for CloudFront to deploy (5-15 min)
- [ ] Tested CloudFront URL (HTTPS)
- [ ] Added CloudFront domain to Firebase
- [ ] Tested all website features (sign up, login, menu, etc.)

**All checked?** 🎉 **YOU'RE LIVE ON AWS!**

---

**Start with STEP 1 and work your way through!** 

**Let me know when you complete each step or if you get stuck!** 🚀
