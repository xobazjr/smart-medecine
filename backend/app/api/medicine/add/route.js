import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function POST(req) {
    try {
        const body = await req.json();
        const {
            drug_name, start_date, start_time, total_drugs,
            each_taken, description, warning, image_url,
            take_morning, take_noon, take_evening, take_bedtime,
            timing, frequency, username
        } = body;

        const user_id = await sql`select user_id from users where username = ${username}`;

        if (!drug_name || !user_id[0].user_id || drug_name === "" || user_id[0].user_id === "") {
            return NextResponse.json(
                {error: "Either drug name or user id is invalid", status: 204},
                {status: 204}
            )
        }

            const newMedicine = await sql`
            INSERT INTO drugs (
                drug_name, start_date, start_time, total_drugs,
                each_taken, description, warning, image_url,
                take_morning, take_noon, take_evening, take_bedtime,
                timing, frequency, user_id
            ) VALUES (
                ${drug_name}, ${start_date || null}, ${start_time || null},
                ${total_drugs || 0}, ${each_taken || 0}, ${description || null},
                ${warning || null}, ${image_url || null}, ${take_morning || 0},
                ${take_noon || 0}, ${take_evening || 0}, ${take_bedtime || 0},
                ${timing || "after"}, ${frequency || "daily"}, ${user_id[0].user_id}
            ) RETURNING drug_id`

        return NextResponse.json(
            {
                message: "New medicine created",
                drug_id: newMedicine[0].drug_id
            }, {status: 201}
        );
    }
    catch (e) {
        return NextResponse.json(
            {error: e, status: 500}
        )
    }
}