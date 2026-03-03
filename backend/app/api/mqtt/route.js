import mqtt from 'mqtt';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic'; // Ensures Next.js doesn't cache this GET request

export async function GET(request) {
    try {
        // Grab the interval from the URL (e.g., ?interval=5), default to 3 if missing
        const { searchParams } = new URL(request.url);
        const intervalParam = searchParams.get('interval') || '3';
        const interval = parseInt(intervalParam, 10);

        const brokerUrl = 'mqtts://l2901b8a.ala.asia-southeast1.emqxsl.com:8883';
        const options = {
            username: 'nextjs_xbjr',
            password: 'nextjs_xbjr',
            clientId: 'nextjs_api_get_' + Math.random().toString(16).substring(2, 8)
        };

        const topicPublish = 'medicine/time/send';
        const topicSubscribe = 'medicine/time/receive';

        // Wrap the whole MQTT process in a Promise
        const boardResponse = await new Promise((resolve, reject) => {
            const client = mqtt.connect(brokerUrl, options);

            // Set an 8-second timeout. If the board doesn't reply by then, cancel it.
            const timeout = setTimeout(() => {
                client.end();
                reject(new Error('Board did not respond in time (Timeout)'));
            }, 8000);

            client.on('connect', () => {
                // 1. Subscribe to the response channel FIRST so we don't miss the reply
                client.subscribe(topicSubscribe, (err) => {
                    if (!err) {
                        // 2. Publish the command to the board
                        const payload = JSON.stringify({ interval: interval });
                        client.publish(topicPublish, payload);
                    } else {
                        clearTimeout(timeout);
                        client.end();
                        reject(err);
                    }
                });
            });

            // 3. Listen for the board's reply
            client.on('message', (topic, message) => {
                if (topic === topicSubscribe) {
                    clearTimeout(timeout); // Stop the timeout clock
                    const replyText = message.toString();

                    client.end(); // Clean up the connection
                    resolve(replyText); // Send the text back to the Next.js API
                }
            });

            client.on('error', (err) => {
                clearTimeout(timeout);
                client.end();
                reject(err);
            });
        });

        // 4. Send the successful response back to Postman!
        return NextResponse.json({
            success: true,
            sent_interval: interval,
            board_reply: boardResponse
        });

    } catch (error) {
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 504 } // 504 Gateway Timeout or 500
        );
    }
}