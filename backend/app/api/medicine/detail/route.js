import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function GET(req) {
    try {
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