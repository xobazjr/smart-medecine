import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import bcrypt from 'bcryptjs';

export async function POST(req) {
    try {
        const body = await req.json();
        const {id} = body;

        if (!id || id === "") {
            return NextResponse.json(
                { error: "Patient id in empty", status: 204},
                { status: 204 }
            )
        }

        const status = await sql`delete from users where user_id = ${id}`;
        return NextResponse.json(status);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}