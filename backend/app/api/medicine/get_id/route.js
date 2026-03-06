import {NextResponse} from 'next/server';
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

        const { searchParams } = new URL(req.url);
        const drugname = searchParams.get('drugname');

        return NextResponse.json(await sql`select drug_id from drugs where drugname=${drugname}`);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}