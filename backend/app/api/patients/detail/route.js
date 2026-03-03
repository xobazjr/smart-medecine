import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import bcrypt from 'bcryptjs';

export async function GET(req) {
    try {
        const { searchParams } = new URL(req.url);
        const username = searchParams.get('username');

        return NextResponse.json(await sql`select user_id, username, tel, role, created_at, caretaker_id, morning_time, noon_time, evening_time, bedtime_time from users where username=${username}`);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}