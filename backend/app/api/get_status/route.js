import { NextResponse } from 'next/server';
import sql from '../../../lib/db';

export async function GET(req) {
    try {
        const query_status = await sql`SELECT * FROM board_status WHERE name = 'esp8266_xbjr' LIMIT 1`;

        if (query_status.length === 0) {
            return NextResponse.json({ error: "Device not found" }, { status: 404 });
        }

        const dbTimestamp = query_status[0].timestamp; // Raw timestamp from DB
        const ts = new Date(dbTimestamp);
        const now = new Date();
        const bkkNow = new Date(now.getTime() + (7 * 60 * 60 * 1000));

        // --- 1. Force formatting to match the DB string exactly (No 7-hour shift) ---
        // We use UTC methods to stop the server from "correcting" the timezone
        const dateStr = ts.getUTCFullYear() + '-' +
            String(ts.getUTCMonth() + 1).padStart(2, '0') + '-' +
            String(ts.getUTCDate()).padStart(2, '0');

        const timeStr = String(ts.getUTCHours()).padStart(2, '0') + ':' +
            String(ts.getUTCMinutes()).padStart(2, '0') + ':' +
            String(ts.getUTCSeconds()).padStart(2, '0');

        console.log(now);

        // --- 2. Raw Time Calculation ---
        const diffInSeconds = Math.floor((bkkNow - ts) / 1000);

        let lastSeen = "";

        // Using raw divisions as requested (no "just now")
        if (diffInSeconds < 60) {
            lastSeen = `${diffInSeconds} second${diffInSeconds !== 1 ? 's' : ''} ago`;
        } else if (diffInSeconds < 3600) {
            const mins = Math.floor(diffInSeconds / 60);
            lastSeen = `${mins} minute${mins > 1 ? 's' : ''} ago`;
        } else if (diffInSeconds < 86400) {
            const hrs = Math.floor(diffInSeconds / 3600);
            lastSeen = `${hrs} hour${hrs > 1 ? 's' : ''} ago`;
        } else {
            const days = Math.floor(diffInSeconds / 86400);
            lastSeen = `${days} day${days > 1 ? 's' : ''} ago`;
        }

        return NextResponse.json({
            timestamp: dbTimestamp,
            date: dateStr,
            time: timeStr,
            datetime: `${dateStr} ${timeStr}`,
            last_seen: lastSeen
        });

    } catch (e) {
        return NextResponse.json({ status: 500, error: e.message }, { status: 500 });
    }
}