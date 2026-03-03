import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';

export async function GET(req) {
    try {
        let patients = [];

        const { searchParams } = new URL(req.url);
        const caretaker = searchParams.get('caretaker_name');
        const find_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.username = ${caretaker}`;
        const find_patient_from_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.caretaker_id = ${find_caretaker[0].user_id}`;
        for (let i = 0; i < find_patient_from_caretaker.length; i++) {
            const userId = find_patient_from_caretaker[i].user_id;

            const drugs = await sql`
        SELECT d.drug_name, d.drug_id, d.warning 
        FROM drugs d
        JOIN users u ON u.user_id = d.user_id
        WHERE u.user_id = ${userId}
    `;
            const user = await sql`select u.username from users u where u.user_id = ${userId}`;

            patients.push({
                username: user[0].username,
                drugs: drugs
            });
        }
        return NextResponse.json(patients);
    }
    catch (e) {
        return NextResponse.json(
            {error: e, status: 500},
            {status: 500}
        )
    }
}