// AWS Lambda Function to return Firebase Configuration
// This keeps your Firebase credentials secure

exports.handler = async (event) => {
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*', // Will be restricted in API Gateway
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET, OPTIONS'
    };
    
    // Handle preflight request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: headers,
            body: ''
        };
    }
    
    // Firebase configuration
    const firebaseConfig = {
        apiKey: "AIzaSyBrtUADtAu6HcniJlrll41hswuj9gnpKWg",
        authDomain: "home-foods-9f024.firebaseapp.com",
        projectId: "home-foods-9f024",
        storageBucket: "home-foods-9f024.appspot.com",
        messagingSenderId: "403437439856",
        appId: "1:403437439856:web:a95a64fc4242552438ddb5",
        measurementId: "G-MGPG1DRHC4"
    };
    
    return {
        statusCode: 200,
        headers: headers,
        body: JSON.stringify(firebaseConfig)
    };
};
