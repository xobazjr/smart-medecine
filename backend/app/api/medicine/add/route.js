import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import jwt from 'jsonwebtoken';

export async function POST(req) {
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
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET || 'default_secret_key');
        } catch (err) {
            return NextResponse.json(
                { error: 'Unauthorized: Invalid token' },
                { status: 401 }
            );
        }

        // 3. Use the user info from the token (optional but recommended)
        // const userIdFromToken = decoded.userId; 
        // const usernameFromToken = decoded.username;

        const body = await req.json();
        const {
            drug_name, start_date, start_time, total_drugs,
            each_taken, description, warning, image_url,
            take_morning, take_noon, take_evening, take_bedtime,
            timing, frequency, username
        } = body;

        // Note: You are currently looking up user_id by username from the body.
        // Ideally, you should use the userId from the token to be more secure.
        // For now, I will keep your logic but you might want to switch to:
        // const user_id = decoded.userId; 

        const user_id_result = await sql`select user_id from users where username = ${username}`;

        if (!drug_name || !user_id_result || user_id_result.length === 0 || !user_id_result[0].user_id) {
             return NextResponse.json(
                {error: "Either drug name or user id is invalid", status: 204},
                {status: 204}
            )
        }
        
        const user_id = user_id_result[0].user_id;

            const newMedicine = await sql`
            INSERT INTO drugs (
                drug_name, start_date, start_time, total_drugs,
                each_taken, description, warning, image_url,
                take_morning, take_noon, take_evening, take_bedtime,
                timing, frequency, user_id
            ) VALUES (
                ${drug_name}, ${start_date || ""}, ${start_time || ""},
                ${total_drugs || 0}, ${each_taken || 0}, ${description || ""},
                ${warning || ""}, ${image_url || ""}, ${take_morning || 0},
                ${take_noon || 0}, ${take_evening || 0}, ${take_bedtime || 0},
                ${timing || "after"}, ${frequency || "daily"}, ${user_id}
            ) RETURNING drug_id`

        return NextResponse.json(
            {
                message: "New medicine created",
                drug_id: newMedicine[0].drug_id
            }, {status: 201}
        );
    }
    catch (e) {
        console.error(e);
        return NextResponse.json(
            {error: e.message, status: 500},
            {status: 500}
        )
    }
}