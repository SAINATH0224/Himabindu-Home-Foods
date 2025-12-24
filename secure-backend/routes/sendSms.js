// routes/sendSms.js
const express = require("express");
const router = express.Router();
const config = require("../config/config.json");
const fetch = require("node-fetch");

// Helper function to get config values with environment variable fallbacks
const getConfig = (section, key) => {
    const envKey = `${section.toUpperCase()}_${key.toUpperCase()}`;
    return process.env[envKey] || config[section][key];
};

// 📱 Secure SMS Sending Route
router.post("/send-sms", async (req, res) => {
    const { message } = req.body;
    const accountSid = getConfig('twilio', 'TWILIO_ACCOUNT_SID');
    const authToken = getConfig('twilio', 'TWILIO_AUTH_TOKEN');
    const twilioNumber = getConfig('twilio', 'TWILIO_PHONE_NUMBER');
    const adminPhone = getConfig('twilio', 'ADMIN_PHONE_NUMBER');

    try {
        const response = await fetch(
            `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
            {
                method: "POST",
                headers: {
                    Authorization: "Basic " + Buffer.from(`${accountSid}:${authToken}`).toString("base64"),
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: new URLSearchParams({
                    From: twilioNumber,
                    To: adminPhone,
                    Body: message,
                }),
            }
        );

        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error("❌ Error sending SMS:", error);
        res.status(500).json({ error: "Error sending SMS" });
    }
});

module.exports = router;