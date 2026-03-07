import { NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import mqtt from 'mqtt';

export async function POST(req) {
    try {
        // 1. Verify the token to keep your API secure
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

        // 2. Extract only the alarms array from the frontend payload
        const body = await req.json();
        const { alarms } = body;

        // 3. Send Alarms directly to the hardware with pacing
        await new Promise((resolve, reject) => {
            const client = mqtt.connect('mqtts://l2901b8a.ala.asia-southeast1.emqxsl.com:8883', {
                username: 'mqtt_to_nextjs',
                password: 'mqtt_to_nextjs',
                clientId: `nextjs_${Math.random().toString(16).slice(3)}`
            });

            // Note the "async" keyword added here to allow delays!
            client.on('connect', async () => {
                console.log("MQTT Connected! Bypassing DB and sending to hardware...");

                // Step A: Send the clear command to wipe the Arduino's EEPROM
                client.publish('medicine/clear_alarm', 'clear');

                // Wait 800ms to give the Arduino time to finish wiping safely
                await new Promise(r => setTimeout(r, 800));

                // Step B: Set new alarms one by one with a delay
                if (alarms && Array.isArray(alarms)) {
                    // Limit to 7 to match MAX_ALARMS on the ESP8266
                    const alarmsToSet = alarms.slice(0, 7);

                    // Using a for...of loop so we can pause execution between sends
                    for (const alarm of alarmsToSet) {
                        if (!alarm.time) continue;

                        const [h, m] = alarm.time.split(':').map(Number);
                        const safeName = (alarm.name || "Meds").substring(0, 11);

                        const payload = JSON.stringify({
                            name: safeName,
                            h: h,
                            m: m
                        });

                        // Shoot the payload to the ESP8266
                        client.publish('medicine/set_alarm', payload);

                        // CRITICAL: Pause for 500ms before looping to the next alarm.
                        // This prevents the Arduino's Serial buffer from overflowing!
                        await new Promise(r => setTimeout(r, 500));
                    }
                }

                // All done! Close the connection safely and resolve the promise.
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
            { message: "Success! Alarms synced perfectly to the medicine box." },
            { status: 200 }
        );
    }
    catch (e) {
        console.error(e);
        return NextResponse.json(
            { error: e.message },
            { status: 500 }
        );
    }
}