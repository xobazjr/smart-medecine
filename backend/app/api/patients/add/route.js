import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import bcrypt from 'bcryptjs';

export async function POST(req) {
    try {
        const body = await req.json();
        const {
            username, password, tel, caretaker_name,
            morning_time, noon_time, evening_time, bedtime_time
        } = body;

        if (!username || !password || !caretaker_name ||
            username === "" || password === "" || caretaker_name === "") {
            return NextResponse.json(
                { error: "Username, password, or caretaker name is null", status: 204 },
                { status: 204 }
            )
        }

        const caretaker_id = await sql`select user_id from users where username = ${caretaker_name}`;
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        const status = await sql`
            INSERT INTO users (
                username,
                password_hash,
                tel,
                caretaker_id,
                morning_time,
                noon_time,
                evening_time,
                bedtime_time
            ) VALUES (
                 ${username},
                 ${password_hash},
                 ${tel || null},
                 ${caretaker_id},
                 ${morning_time ?? "8:00:00"},
                 ${noon_time ?? "12:00:00"},
                 ${evening_time ?? "18:00:00"},
                 ${bedtime_time ?? "22:00:00"}     
            ) RETURNING user_id, username, role, tel;
        `;

        return NextResponse.json(status);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}