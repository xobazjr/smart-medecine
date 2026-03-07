import { NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import mqtt from 'mqtt';

export async function POST(req) {
    try {
        // 1. Verify the token to ensure the request is authorized
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

        // 2. Connect to MQTT and send the clear command
        await new Promise((resolve, reject) => {
            const client = mqtt.connect('mqtts://l2901b8a.ala.asia-southeast1.emqxsl.com:8883', {
                username: 'mqtt_to_nextjs',
                password: 'mqtt_to_nextjs',
                clientId: `nextjs_clear_${Math.random().toString(16).slice(3)}`
            });

            client.on('connect', () => {
                console.log("MQTT Connected! Wiping alarms...");

                // Shoot the clear command to the ESP8266
                client.publish('medicine/clear_alarm', 'clear');

                // Wait 500ms to ensure the message successfully leaves the server
                setTimeout(() => {
                    client.end();
                    resolve(true);
                }, 500);
            });

            client.on('error', (err) => {
                console.error('MQTT Connection Error:', err);
                client.end();
                resolve(false);
            });
        });

        return NextResponse.json(
            { message: "Clear command sent. All alarms wiped from the hardware!" },
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