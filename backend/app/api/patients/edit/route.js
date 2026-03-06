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
        const { id,
            username, password, tel, caretaker_name,
            morning_time, noon_time, evening_time, bedtime_time
        } = body;

        const oldPatient = await sql`SELECT * FROM users WHERE user_id = ${id}`;

        if (!id || id === "") {
            return NextResponse.json(
                { error: "Id is null", status: 204 },
                { status: 204 }
            )
        }

        if (oldPatient.length === 0) {
            return NextResponse.json({ error: "Patient not found", status: 404 }, { status: 404 })
        }

        const caretaker_id = await sql`select user_id from users where username = ${caretaker_name}`;
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        const finalQuery = await sql`
            UPDATE users SET
                             username = ${username ?? oldPatient[0].username},
                             password_hash = ${password_hash ?? oldPatient[0].password_hash},
                             tel = ${tel ?? oldPatient[0].tel},
                             caretaker_id = ${caretaker_id[0].user_id ?? oldPatient[0].caretaker_id},
                             morning_time = ${morning_time ?? oldPatient[0].morning_time},
                             noon_time = ${noon_time ?? oldPatient[0].noon_time},
                             evening_time = ${evening_time ?? oldPatient[0].evening_time},
                             bedtime_time = ${bedtime_time ?? oldPatient[0].bedtime_time}
            WHERE user_id = ${id}
        `;

        return NextResponse.json(finalQuery);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}