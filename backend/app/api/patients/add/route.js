import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import bcrypt from 'bcryptjs';
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
        try {
            jwt.verify(token, process.env.JWT_SECRET || 'default_secret_key');
        } catch (err) {
            return NextResponse.json(
                { error: 'Unauthorized: Invalid token' },
                { status: 401 }
            );
        }

        const body = await req.json();
        const {
            username, password, tel, caretaker_name,
            morning_time, noon_time, evening_time, bedtime_time
        } = body;

        if (!username || !password || !caretaker_name ||
            username === "" || password === "" || caretaker_name === "") {
            return NextResponse.json(
                {error: "Username, password, or caretaker name is null"},
                {status: 400}
            );
        }

        const caretaker_id = await sql`select user_id
                                       from users
                                       where username = ${caretaker_name}`;

        if (caretaker_id.length === 0) {
            return NextResponse.json({error: "Caretaker not found"}, {status: 404});
        }

        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        const status = await sql`
            INSERT INTO users (
                username, password_hash, tel, webhook_url_discord, webhook_url_line,
                role, caretaker_id, morning_time, noon_time, evening_time, bedtime_time
            )
            VALUES (
                       ${username}, ${password_hash}, ${tel || ''}, '', '',
                       'elderly', ${caretaker_id[0].user_id},
                       ${morning_time ?? '08:00:00'}, ${noon_time ?? '12:00:00'},
                       ${evening_time ?? '18:00:00'}, ${bedtime_time ?? '22:00:00'}
                   ) RETURNING user_id, username, tel;
        `;

        return NextResponse.json(status);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}