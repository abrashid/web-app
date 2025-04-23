import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const ddbClient = new DynamoDBClient({ region: "eu-west-1" });
const ddb = DynamoDBDocumentClient.from(ddbClient);

async function handler(event) {
  const userId = event.queryStringParameters?.userId;
  const params = {
    TableName: "web-app-UserData",
    Key: { userId }
  };
  try {
    const command = new GetCommand(params);
    const { Item } = await ddb.send(command);
    if (Item) {
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': 'https://<some-auto-generated-random-numbers>.cloudfront.net'
            },
            body: JSON.stringify(Item)
        };
    } else {
        return {
            statusCode: 404,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': 'https://<some-auto-generated-random-numbers>.cloudfront.net'
            },
            body: JSON.stringify({ message: "User not found" })
        };
    }
   } catch (err) {
        console.error("Unable to retrieve data:", err);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': 'https://<some-auto-generated-random-numbers>.cloudfront.net'
            },
            body: JSON.stringify({ message: "Failed to retrieve user data" })
        };
     }
}

export { handler };
