import {NextResponse} from 'next/server';
import sql from '../../../lib/db';

export async function GET(req, res) {
    try {
        const query = await sql`SELECT tel FROM users WHERE username = 'winsanmwtv' LIMIT 1`;
        return NextResponse.json({
            message: "API is working",
            data: query
        });
    } catch (e) {
        console.error("Login error: ", e);
        return NextResponse.json(
            { error: "Internal server error", details: e.message },
            { status: 500 }
        )
    }
}