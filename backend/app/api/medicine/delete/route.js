import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function POST(req) {
    try {
        const body = await req.json();
        const {id} = body;

        if (!id || id === "") {
            return NextResponse.json(
                {error: "Drug id is empty", status: 204},
                {status: 204}
            )
        }

        const status = await sql`delete from drugs where drug_id = ${id}`;
        return NextResponse.json(status);
    }
    catch (e) {
        return NextResponse.json(
            {error: e, status: 500}
        )
    }
}