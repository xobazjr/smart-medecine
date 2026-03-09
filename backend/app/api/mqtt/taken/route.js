import { NextResponse } from 'next/server';
import sql from '../../../../lib/db';

export async function POST(req) {
    try {

        const body = await req.json();
        console.log("Incoming body:", body);

        const { weight, time, user_id, drug_id } = body;

        // fallback values if missing
        const uid = user_id || 1;
        const did = drug_id || 1;

        // parse time
        const takenAt = time ? new Date(time) : new Date();

        // determine status
        const weightVal = parseFloat(weight);
        const status = weightVal > 1.0 ? 'taken' : 'missed';

        const newHistory = await sql`
            INSERT INTO medication_history (
                drug_id,
                user_id,
                drug_name,
                status,
                meal_period,
                taken_at,
                scheduled_date
            ) VALUES (
                ${did},
                ${uid},
                (SELECT drug_name FROM drugs WHERE drug_id = ${did}),
                ${status},
                'unknown',
                ${takenAt},
                ${takenAt}
            )
            RETURNING history_id
        `;

        return NextResponse.json({
            success: true,
            history_id: newHistory[0].history_id
        });

    } catch (error) {
        console.error("MQTT Taken Error:", error);

        return NextResponse.json(
            {
                error: "Internal server error",
                details: error.message
            },
            { status: 500 }
        );
    }
}