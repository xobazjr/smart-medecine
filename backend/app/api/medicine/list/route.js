import { NextResponse } from 'next/server';
import sql from '../../../../lib/db';
import jwt from 'jsonwebtoken';

export async function GET(req) {
    try {
        // 1. Extract the token from the Authorization header
        const authHeader = req.headers.get('authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return NextResponse.json(
                { error: 'Unauthorized: Missing or invalid token' },
                { status: 401 }
            );
        }

        const token = authHeader.split(' ')[1];

        // 2. Verify the token
        try {
            jwt.verify(token, process.env.JWT_SECRET || 'default_secret_key');
        } catch (err) {
            return NextResponse.json(
                { error: 'Unauthorized: Invalid token' },
                { status: 401 }
            );
        }

        let patients = [];

        const { searchParams } = new URL(req.url);
        const caretaker = searchParams.get('caretaker_name');

        if (!caretaker || caretaker === '') {
            return NextResponse.json(
                { error: "bad request, caretaker name must not be null" },
                { status: 400 }
            );
        }

        const patient_name = searchParams.get('pid') ?? '';
        const befaft_meals = searchParams.get('meal') ?? '';
        const time_flags = searchParams.get('time') ?? '';

        const find_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.username = ${caretaker}`;

        // Safety check in case the caretaker doesn't exist
        if (find_caretaker.length === 0) {
            return NextResponse.json({ error: "Caretaker not found" }, { status: 404 });
        }

        let find_patient_from_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.caretaker_id = ${find_caretaker[0].user_id}`;

        if (patient_name !== '') {
            // Added a check to ensure the searched patient actually belongs to this caretaker
            find_patient_from_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.user_id = ${pid} AND u.caretaker_id = ${find_caretaker[0].user_id}`;
        }

        for (let i = 0; i < find_patient_from_caretaker.length; i++) {
            const userId = find_patient_from_caretaker[i].user_id;

            // 1. Setup the mneb flags using a switch case
            let m = false, n = false, e = false, b = false;

            if (time_flags !== '') {
                // Loop through each character (e.g., 'mneb', 'mn')
                for (let char of time_flags.toLowerCase()) {
                    switch (char) {
                        case 'm': m = true; break;
                        case 'n': n = true; break;
                        case 'e': e = true; break;
                        case 'b': b = true; break;
                    }
                }
            }

            // 2. Fetch the user info
            const user = await sql`SELECT u.username FROM users u WHERE u.user_id = ${userId}`;

            // 3. Fetch all drugs for this user
            // Note: Make sure your SELECT statement includes the columns you need for the flags (e.g., morning, noon, etc.)
            let drugs = await sql`
                SELECT d.drug_name, d.drug_id, d.warning, d.timing, d.take_morning, d.take_noon, d.take_evening, d.take_bedtime 
                FROM drugs d 
                JOIN users u ON u.user_id = d.user_id 
                WHERE u.user_id = ${userId}
            `;

            // 4. Apply the filters (This allows both 'meal' and 'time' to be true at the same time)
            if (befaft_meals !== '') {
                drugs = drugs.filter(d => d.timing === befaft_meals);
            }

            if (time_flags !== '') {
                // Assuming your DB has boolean columns: morning, noon, evening, bedtime
                drugs = drugs.filter(d =>
                    (m && d.take_morning) ||
                    (n && d.take_noon) ||
                    (e && d.take_evening) ||
                    (b && d.take_bedtime)
                );
            }

            patients.push({
                username: user[0]?.username,
                drugs: drugs
            });
        }

        return NextResponse.json(patients);
    }
    catch (e) {
        console.error("API Error:", e); // Helpful for debugging server-side
        return NextResponse.json(
            { error: e.message || "Internal Server Error", status: 500 },
            { status: 500 }
        )
    }
}