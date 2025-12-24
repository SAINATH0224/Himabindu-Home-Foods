# Home Foods 🍲

A full-stack web application for ordering delicious homemade food. Features a user-friendly frontend built with HTML/CSS/JavaScript and a secure backend API deployed on Vercel with Firebase integration.

## Project Overview

Home Foods is a platform that connects food lovers with home-cooked meals. The application consists of two main components:

- **Frontend** (HOMEFODS-main): Interactive web interface for browsing menus and placing orders
- **Backend** (secure-backend): Secure API server handling user authentication, orders, and SMS notifications

## Features

✨ **Frontend Features:**
- Responsive homepage with featured items
- Interactive menu browsing
- User authentication (Sign In/Sign Up)
- Order placement system
- Dashboard for viewing orders
- Mobile-friendly design

🔐 **Backend Features:**
- Firebase authentication integration
- Secure credential handling
- SMS notifications via Twilio
- RESTful API endpoints
- Environment-based configuration
- Vercel serverless deployment

## Project Structure

```
Himabindu-Home-Foods/
├── HOMEFODS-main/              # Frontend application
│   ├── index.html              # Homepage
│   ├── menu.html               # Menu page
│   ├── ordernow.html           # Order page
│   ├── signin.html             # Sign in page
│   ├── signup.html             # Sign up page
│   ├── dashboard.html          # User dashboard
│   ├── package.json            # Frontend dependencies
│   ├── lambda-firebase-config/ # Lambda function for Firebase config
│   └── [Images and assets]     # Food images and resources
│
└── secure-backend/             # Backend API
    ├── server.js               # Main server file
    ├── package.json            # Backend dependencies
    ├── vercel.json             # Vercel deployment config
    ├── config/
    │   └── config.json         # Configuration (excluded from git)
    └── routes/
        ├── credentials.js      # Authentication routes
        └── sendSms.js          # SMS notification routes
```

## Prerequisites

- **Node.js** (v14 or higher)
- **npm** or **yarn**
- **Firebase** account and project setup
- **Twilio** account for SMS functionality
- **Git** for version control
- **Vercel** account for backend deployment (optional)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/SAINATH0224/Himabindu-Home-Foods.git
cd Himabindu-Home-Foods
```

### 2. Frontend Setup (HOMEFODS-main)

```bash
cd HOMEFODS-main
npm install
```

**To run locally:**
```bash
# Use a local server (Python 3)
python -m http.server 8000

# Or use Node.js live-server
npx live-server
```

The frontend will be available at `http://localhost:8000` or `http://localhost:8080`

### 3. Backend Setup (secure-backend)

```bash
cd ../secure-backend
npm install
```

**Create `config/config.json`** with your credentials:

```json
{
  "firebase": {
    "apiKey": "YOUR_FIREBASE_API_KEY",
    "authDomain": "your-project.firebaseapp.com",
    "projectId": "your-project-id",
    "storageBucket": "your-project.appspot.com",
    "messagingSenderId": "YOUR_MESSAGING_ID",
    "appId": "YOUR_APP_ID"
  },
  "twilio": {
    "accountSid": "YOUR_TWILIO_ACCOUNT_SID",
    "authToken": "YOUR_TWILIO_AUTH_TOKEN",
    "phoneNumber": "+1234567890"
  }
}
```

**To run locally:**
```bash
npm start
# or
node server.js
```

The backend will run on `http://localhost:3000` (or as configured)

## Configuration

### Environment Variables

The backend uses a `config/config.json` file to store sensitive information:

- **Firebase Credentials**: Required for user authentication
- **Twilio Credentials**: Required for SMS notifications
- **API Keys**: For third-party service integrations

⚠️ **IMPORTANT**: Never commit `config/config.json` to version control. It's already added to `.gitignore`.

## Deployment

### Frontend Deployment

The frontend can be deployed to:
- **AWS S3 + CloudFront**
- **Netlify**
- **Vercel**
- **Firebase Hosting**

### Backend Deployment (Vercel)

The secure-backend is configured for Vercel deployment:

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   cd secure-backend
   vercel
   ```

3. **Set environment variables on Vercel dashboard:**
   - Add Firebase configuration
   - Add Twilio credentials
   - Any other required environment variables

4. **Update frontend API endpoints** to point to your Vercel deployment URL

## API Endpoints

### Authentication (`/routes/credentials.js`)
- `POST /api/auth/signin` - User sign in
- `POST /api/auth/signup` - User registration
- `POST /api/auth/verify` - Verify credentials

### Notifications (`/routes/sendSms.js`)
- `POST /api/notify/sms` - Send SMS notification
- `POST /api/notify/order` - Send order confirmation

## Technologies Used

### Frontend
- HTML5
- CSS3
- JavaScript (Vanilla)
- Firebase SDK

### Backend
- Node.js
- Express.js
- Firebase Admin SDK
- Twilio SDK
- Vercel (Serverless)

## Usage

1. **Browse Menu**: Navigate to the menu page to view available food items
2. **Create Account**: Sign up with email and password
3. **Place Order**: Select items and place your order
4. **Receive Confirmation**: Get SMS notification once order is placed
5. **Track Order**: Use dashboard to track your orders

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security

- 🔒 Sensitive credentials are stored in environment variables
- 🔐 Firebase handles user authentication
- 📱 Twilio for secure SMS delivery
- 🚫 No secrets are committed to the repository

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

---

**Made by Sainath and Abhiram | Home Foods 2025**
