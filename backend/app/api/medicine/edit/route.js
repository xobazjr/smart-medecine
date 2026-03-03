import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function POST(req) {
    try {
        const body = await req.json();
        const { id, drug_name, start_date, start_time, total_drugs,
                each_taken, description, warning, image_url,
                take_morning, take_noon, take_evening, take_bedtime,
                timing, frequency } = body;

        const oldDrug = await sql`
  SELECT * FROM drugs WHERE drug_id = ${id}
`;

        if (!id || id === "") {
            return NextResponse.json(
                {error: "Drug id is invalid or empty", status: 204},
                {status: 204}
            )
        }

        if (oldDrug.length === 0) {
            return NextResponse.json({ error: "Drug not found" }, { status: 404 });
        }

        await sql`
  UPDATE drugs SET
    drug_name = ${drug_name ?? oldDrug[0].drug_name},
    start_date = ${start_date ?? oldDrug[0].start_date},
    start_time = ${start_time ?? oldDrug[0].start_time},
    total_drugs = ${total_drugs ?? oldDrug[0].total_drugs},
    each_taken = ${each_taken ?? oldDrug[0].each_taken},
    description = ${description ?? oldDrug[0].description},
    warning = ${warning ?? oldDrug[0].warning},
    image_url = ${image_url ?? oldDrug[0].image_url},
    take_morning = ${take_morning ?? oldDrug[0].take_morning},
    take_noon = ${take_noon ?? oldDrug[0].take_noon},
    take_evening = ${take_evening ?? oldDrug[0].take_evening},
    take_bedtime = ${take_bedtime ?? oldDrug[0].take_bedtime},
    timing = ${timing ?? oldDrug[0].timing},
    frequency = ${frequency ?? oldDrug[0].frequency}
  WHERE drug_id = ${id}
`;

        return NextResponse.json({ success: true });
    }
    catch (e) {
        return NextResponse.json(
            {error: e, status: 500}
        )
    }
}