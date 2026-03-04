import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function GET(req) {
    try {
        const { searchParams } = new URL(req.url);
        const username = searchParams.get('username');

        return NextResponse.json(await sql`select user_id from users where username=${username}`);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}