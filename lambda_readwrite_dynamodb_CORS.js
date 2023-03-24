const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
    const pageName = "1";

    const params = {
        TableName: 'VisitorCountTerraform', // MODIFY WITH THE NAME OF THE TABLE
        Key: {
            PageName: pageName
        },
        UpdateExpression: 'ADD #count :incr',
        ExpressionAttributeNames: {
            '#count': 'Count'
        },
        ExpressionAttributeValues: {
            ':incr': 1
        },
        ReturnValues: 'UPDATED_NEW'
    };

    ddb.update(params, function(err, data) {
        if (err) {
            console.error(err);
            errorResponse(err.message, context.awsRequestId, callback);
        } else {
            console.log(`Visitor count for page ${pageName} updated to ${data.Attributes.Count}`);
            callback(null, {
                statusCode: 200,
                body: JSON.stringify({
                    Count: data.Attributes.Count
                }),
                headers: {
                    'Access-Control-Allow-Origin': '*',
                },
            });
        }
    });
};

function errorResponse(errorMessage, awsRequestId, callback) {
    callback(null, {
        statusCode: 500,
        body: JSON.stringify({
            Error: errorMessage,
            Reference: awsRequestId,
        }),
        headers: {
            'Access-Control-Allow-Origin': '*',
        },
    });
}
