const awsServerlessExpress = require('aws-serverless-express');
const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());

// key value object with 12 items and random text for each
const jigsaw_stalls = {
    'Kj3': '1',
    'hjNqv': '2',
    'zX98n': '3',
    'm78': '4',
    'kXmzM': '5',
    'q9X4': '6',
    '2k4': '7',
    'M3Hv': '8',
    'd7G': '9',
    '4h4': '10',
    'tX4': '11',
    'J78': '12'
}

// middleware to attach ip address of client
app.use((req, res, next) => {
    // if (req.apiGateway && req.apiGateway.event.requestContext) {
    //     req.ip = req.apiGateway.event.requestContext.identity.sourceIp;
    // }
    // use X-Forwarded-For header for client ip address
    if (req.headers['x-forwarded-for']) {
        req.ip = req.headers['x-forwarded-for'].split(',')[0];
    }
    next();
});

app.get('/', (req, res) => {
    res.send('Hello, world! ' + req.jigsaw);
});

// jigsaw endpoint is endpoint for qr code scans
app.get('/jigsaw', (req, res) => {
    const userAgentasync  = req.get('User-Agent');

    const AWS = require('aws-sdk');
    const docClient = new AWS.DynamoDB.DocumentClient({region: 'ap-southeast-2'});

    const data = {
        'userAgent': userAgentasync,
        'acceptLanguage': req.get('Accept-Language'),
        'acceptEncoding': req.get('Accept-Encoding'),
        'ipAddr': req.ip,
        'date' : new Date().toISOString()
    }
    const hash = require('object-hash');
    const id = hash(data);
    data.id = id;

    const stall = req.query.stall;
    const putItem = {
        'id' : id,
        'time': new Date().toISOString(),
        'stall': jigsaw_stalls[stall] || 'unknown'
    };

    const response = {
        id: id,
        message: 'Hello new person!',
        time: new Date().toISOString(),
        stall: putItem.stall,
    }

    const putParams = {
        TableName: 'jigsaw',
        Item: putItem
    };

    docClient.put(putParams).promise()
    .then(data => {
        console.log('Successfully added item to DynamoDB', data);
        response.message = "successfully added item to dynamodb"
        res.send(`
        <html>

        <head>
            <title>QR Code Scanner</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            body {
                display: flex;
                justify-content: center;
                align-items: center;
                flex-direction: column;
                height: 100vh;
                margin: 0;
                background-color: #f0f0f0;
                font-family: Arial, sans-serif;
                color: #333;
            }
        
            h1 {
                font-size: 2em;
                text-align: center;
            }
        
            .animated-text {
                /* font-size: 2em; */
                animation: pulse 2s infinite;
                text-align: center;
            }
        
            @keyframes pulse {
                0% {
                    transform: scale(1);
                }
                50% {
                    transform: scale(1.1);
                }
                100% {
                    transform: scale(1);
                }
            }
        </style>
        </head>
        <body>
        <div>
            <h1 >Thanks for scanning into stall ${response.stall}</h1>
        </div>
        <div>
            <p class="animated-text">Scan another QR code to scan into another stall</p>
        </div>
        </body>
        </html>
        `);
        
        // res.json(response);
    })
    .catch(err => {
        console.log("Error adding item: ", err);
        response.message = "Error adding item: " + err.message;
        res.json(response);
    });

    console.log("Hash " + id);
});

// puzzle endpoint is for the puzzle game's frontend.
app.get('/puzzle', (req, res) => {
    const userAgent = req.get('User-Agent');

    // return a bunch of html and javascript files
    // res.send(`
    res.sendFile('index.html', {root: __dirname});

});
// puzzle endpoint is for the puzzle game's frontend.
app.get('/solve', (req, res) => {
    const stall_id = req.query.stall;
    const stall = jigsaw_stalls[stall_id] || 'unknown';

    const AWS = require('aws-sdk');
    const docClient = new AWS.DynamoDB.DocumentClient({region: 'ap-southeast-2'});
    const params = {
        TableName: 'jigsaw',
        FilterExpression: 'stall = :stall',
        ExpressionAttributeValues: {
            ':stall': stall
        },
        Select: 'COUNT'
    };
    
    docClient.scan(params).promise()
    .then(data => {
        console.log('Successfully scanned dynamodb', data);

        res.json({
            count: data.Count,
            stall: stall
        });
    })
    .catch(err => {
        console.log("Error scanning dynamodb: ", err);
        res.json({
            count: 0,
            stall: stall
        });
    });
});

const server = awsServerlessExpress.createServer(app);

exports.handler = (event, context) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    event.requestContext.identity.sourceIp = event.requestContext.identity.sourceIp || 'unknown';
    awsServerlessExpress.proxy(server, event, context);
};