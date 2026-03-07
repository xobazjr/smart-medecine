import { NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import mqtt from 'mqtt';

export async function POST(req) {
    try {
        // 1. Verify the token to ensure the user is authorized
        const authHeader = req.headers.get('authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return NextResponse.json(
                { error: 'Unauthorized: Missing or invalid token' },
                { status: 401 }
            );
        }

        const token = authHeader.split(' ')[1];
        try {
            jwt.verify(token, process.env.JWT_SECRET || 'default_secret_key');
        } catch (err) {
            return NextResponse.json(
                { error: 'Unauthorized: Invalid token' },
                { status: 401 }
            );
        }

        // 2. Connect to MQTT and send Refill & Tare commands
        await new Promise((resolve, reject) => {
            const client = mqtt.connect('mqtts://l2901b8a.ala.asia-southeast1.emqxsl.com:8883', {
                username: 'mqtt_to_nextjs',
                password: 'mqtt_to_nextjs',
                clientId: `nextjs_refill_${Math.random().toString(16).slice(3)}`
            });

            // Added async here so we can use await for the delay
            client.on('connect', async () => {
                console.log("MQTT Connected for Refill!");

                // Step A: Send the refill command to open the servo
                client.publish('medicine/refill', 'open_box');

                // Wait 2 seconds before sending the Tare command.
                // This prevents the ESP8266 Serial buffer from overflowing.
                await new Promise(resolve => setTimeout(resolve, 2000));

                // Step B: Send the tare command.
                // The Arduino will hold this in its buffer and execute it EXACTLY
                // when its mechanical refill delay finishes!
                client.publish('medicine/tare', 'reset_scale');

                // Close connection safely
                client.end();
                resolve(true);
            });

            client.on('error', (err) => {
                console.error('MQTT Connection Error:', err);
                client.end();
                resolve(false);
            });
        });

        return NextResponse.json(
            { message: "Refill command sent. The box will open for 1 minute." },
            { status: 200 }
        );

    }
    catch (e) {
        console.error(e);
        return NextResponse.json(
            { error: e.message, status: 500 },
            { status: 500 }
        );
    }
}