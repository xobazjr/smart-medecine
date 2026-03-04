import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function GET(req) {
    try {
        const { searchParams } = new URL(req.url);
        const drugname = searchParams.get('drugname');

        return NextResponse.json(await sql`select drug_id from drugs where drugname=${drugname}`);
    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}