import {NextResponse} from 'next/server';
import sql from '../../../../lib/db';
import bcrypt from 'bcryptjs';

export async function GET(req) {
    try {

        const { searchParams } = new URL(req.url);
        const caretaker = searchParams.get('caretaker_name');
        const find_caretaker = await sql`SELECT u.user_id FROM users u WHERE u.username = ${caretaker}`;
        const find_patient_from_caretaker = await sql`SELECT u.username, u.user_id FROM users u WHERE u.caretaker_id = ${find_caretaker[0].user_id}`;

        let patients = [];

        for (let i = 0; i < find_patient_from_caretaker.length; i++) {
            patients.push({
               username: find_patient_from_caretaker[i].username,
               user_id: find_patient_from_caretaker[i].user_id
            });
        }

        return NextResponse.json(patients);

    } catch (e) {
        return NextResponse.json(
            {error: e}, {status: 500}
        )
    }
}