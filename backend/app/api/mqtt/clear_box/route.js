import { NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import mqtt from 'mqtt';

export async function POST(req) {
    try {

        // 1. Verify token
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

        // =========================
        // CHECK BOARD STATUS
        // =========================
        const statusRes = await fetch(`${process.env.BASE_URL || 'https://smart-medicine-topaz.vercel.app'}/api/get_status`);
        const status = await statusRes.json();

        if (!status.is_online) {
            return NextResponse.json(
                { error: "Can't connect to board (offline)" },
                { status: 500 }
            );
        }

        const lastSeen = new Date(status.timestamp);
        const now = new Date();
        const diffSeconds = (now - lastSeen) / 1000;

        if (diffSeconds > 60) {
            return NextResponse.json(
                { error: "Can't connect to board (last seen > 1 minute)" },
                { status: 500 }
            );
        }

        // =========================
        // SEND CLEAR COMMAND
        // =========================
        await new Promise((resolve) => {

            const client = mqtt.connect(
                'mqtts://l2901b8a.ala.asia-southeast1.emqxsl.com:8883',
                {
                    username: 'mqtt_to_nextjs',
                    password: 'mqtt_to_nextjs',
                    clientId: `nextjs_clear_${Math.random().toString(16).slice(3)}`
                }
            );

            client.on('connect', () => {

                console.log("MQTT Connected! Wiping alarms...");

                client.publish('medicine/clear_alarm', 'clear');

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

    } catch (e) {

        console.error(e);

        return NextResponse.json(
            { error: e.message },
            { status: 500 }
        );

    }
}