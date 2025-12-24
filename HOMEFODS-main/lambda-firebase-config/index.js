// AWS Lambda Function to Return Firebase Configuration
exports.handler = async (event) => {
    // Firebase Configuration
    const firebaseConfig = {
        apiKey: "AIzaSyBrtUADtAu6HcniJlrll41hswuj9gnpKWg",
        authDomain: "home-foods-9f024.firebaseapp.com",
        projectId: "home-foods-9f024",
        storageBucket: "home-foods-9f024.appspot.com",
        messagingSenderId: "403437439856",
        appId: "1:403437439856:web:a95a64fc4242552438ddb5",
        measurementId: "G-MGPG1DRHC4"
    };

    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*', // Will be restricted after setup
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Content-Type': 'application/json'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: headers,
            body: ''
        };
    }

    // Return Firebase config
    return {
        statusCode: 200,
        headers: headers,
        body: JSON.stringify(firebaseConfig)
    };
};
