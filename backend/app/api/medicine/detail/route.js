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
        const drugId = searchParams.get('drugId');

        if (!drugId || drugId === "") {
            return NextResponse.json(
                {error: "Drug ID is invalid or empty", status: 204},
                {status: 204}
            )
        }

        const drug = await sql`select * from drugs where drug_id = ${drugId}`;
        return NextResponse.json(drug);
    }
    catch (e) {
        return NextResponse.json(
            {error: e, status: 500}
        )
    }
}