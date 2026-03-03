import { NextResponse } from 'next/server';
import sql from '../../../lib/db';

export async function POST(req) {
    try {
        const body = await req.json();

        const { msg, time } = body;
        //
        // if (msg !== "I'm alive") {
        //     return NextResponse.json(
        //         { status: 400, error: "Bad request" },
        //         { status: 400 }
        //     );
        // }
        await sql`UPDATE board_status SET timestamp = ${time} WHERE name = 'esp8266_xbjr'`;
        return NextResponse.json({ status: 200, success: true }, { status: 200 } )
    } catch (e) {
        return NextResponse.json({
           status: 500, error: e
        }, {
            status: 500
        });
    }
}