const express = require("express");
const router = express.Router();
const config = require("../config/config.json");

// Helper function to get config values with environment variable fallbacks
const getConfig = (section, key) => {
    const envKey = `${section.toUpperCase()}_${key.toUpperCase()}`;
    return process.env[envKey] || config[section][key];
};

// Add CORS headers to all routes in this router
router.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "http://127.0.0.1:5500","https://abhiramreddyvundhyala.github.io");
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    next();
});

// Firebase credentials endpoint
router.get("/firebase", (req, res) => {
    res.json({
        apiKey: getConfig('firebase', 'apiKey'),
        authDomain: getConfig('firebase', 'authDomain'),
        projectId: getConfig('firebase', 'projectId'),
        storageBucket: getConfig('firebase', 'storageBucket'),
        messagingSenderId: getConfig('firebase', 'messagingSenderId'),
        appId: getConfig('firebase', 'appId')
    });
});

// EmailJS credentials endpoint
router.get("/emailjs", (req, res) => {
    res.json({
        EMAIL_PUBLIC_KEY: getConfig('emailjs', 'EMAIL_PUBLIC_KEY'),
        EMAIL_SERVICE_ID: getConfig('emailjs', 'EMAIL_SERVICE_ID'),
        EMAIL_TEMPLATE_ID: getConfig('emailjs', 'EMAIL_TEMPLATE_ID')
    });
});

// Twilio credentials endpoint
router.get("/twilio", (req, res) => {
    res.json({
        accountSid: getConfig('twilio', 'TWILIO_ACCOUNT_SID'),
        twilioNumber: getConfig('twilio', 'TWILIO_PHONE_NUMBER'),
        adminPhone: getConfig('twilio', 'ADMIN_PHONE_NUMBER')
    });
});

module.exports = router;