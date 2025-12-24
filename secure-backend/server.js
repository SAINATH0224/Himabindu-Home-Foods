const express = require("express");
const cors = require("cors");
const app = express();
const config = require("./config/config.json");

// 1. Configure CORS middleware with more specific options
const corsOptions = {
    origin: [
        "http://127.0.0.1:5500", 
        "http://localhost:5500",
        "https://abhiramreddyvundhyala.github.io",
        "https://d3fe13j8cyielm.cloudfront.net",  // ← ADD THIS (Your AWS CloudFront URL)
        "http://homefods-website-2025.s3-website-us-east-1.amazonaws.com"  // ← ADD THIS (Your S3 URL - optional)
    ],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
    credentials: true,
    maxAge: 86400
};

app.use(cors(corsOptions));
    
// 2. Handle preflight requests globally
app.options('*', (req, res) => {
    res.status(200).end();
});

app.use(express.json());

// 3. Add CORS headers directly as fallback - helps with Vercel deployments
app.use((req, res, next) => {
    const allowedOrigins = [
        "http://127.0.0.1:5500",
        "http://localhost:5500",
        "https://abhiramreddyvundhyala.github.io",
        "https://d3fe13j8cyielm.cloudfront.net"  // ← Add your CloudFront URL
    ];
    
    const origin = req.headers.origin;
    if (allowedOrigins.includes(origin)) {
        res.header("Access-Control-Allow-Origin", origin);
    }
    
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
    res.header("Access-Control-Allow-Credentials", "true");
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    
    next();
});

// Define routes
const credentialsRoute = require("./routes/credentials");
const sendSmsRoute = require("./routes/sendSms");

// Mount routes
app.use("/api/credentials", credentialsRoute);
app.use("/api", sendSmsRoute);

// Root endpoint
app.get("/", (req, res) => {
    res.send("✅ Secure API is running!");
});

// For local development
if (process.env.NODE_ENV !== 'production') {
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
}

// For Vercel
module.exports = app;