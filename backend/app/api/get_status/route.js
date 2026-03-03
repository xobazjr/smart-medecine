import { NextResponse } from 'next/server';
import sql from '../../../lib/db';

export async function GET(req) {
    try {
        const query_status = await sql`SELECT * FROM board_status WHERE name = 'esp8266_xbjr' LIMIT 1`;

        if (query_status.length === 0) {
            return NextResponse.json({ error: "Device not found" }, { status: 404 });
        }

        // 1. Get the raw timestamp from the DB
        const ts = new Date(query_status[0].timestamp);
        const now = new Date();

        // 2. Force strings to Bangkok Time (UTC+7)
        // This prevents the "3 AM" shift by ignoring the server's local clock.
        const tz = 'Asia/Bangkok';
        const dateStr = ts.toLocaleDateString('en-CA', { timeZone: tz }); // YYYY-MM-DD
        const timeStr = ts.toLocaleTimeString('en-GB', { timeZone: tz, hour12: false }); // HH:MM:SS
        const datetimeStr = `${dateStr} ${timeStr}`;

        // 3. Calculate "Time Ago"
        // We use Math.floor to get the total seconds difference
        const diffInSeconds = Math.floor((now - ts) / 1000);

        let lastSeen = "";

        // Handle small clock drifts (if diff is slightly negative, it's "just now")
        if (diffInSeconds < 5) {
            lastSeen = "just now";
        } else if (diffInSeconds < 60) {
            lastSeen = `${diffInSeconds} seconds ago`;
        } else if (diffInSeconds < 3600) {
            const minutes = Math.floor(diffInSeconds / 60);
            lastSeen = `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
        } else if (diffInSeconds < 86400) {
            const hours = Math.floor(diffInSeconds / 3600);
            lastSeen = `${hours} hour${hours > 1 ? 's' : ''} ago`;
        } else {
            const days = Math.floor(diffInSeconds / 86400);
            lastSeen = `${days} day${days > 1 ? 's' : ''} ago`;
        }

        return NextResponse.json({
            timestamp: ts.toISOString(),
            date: dateStr,
            time: timeStr,
            datetime: datetimeStr,
            last_seen: lastSeen
        });

    } catch (e) {
        console.error("GET Status Error:", e);
        return NextResponse.json({ status: 500, error: e.message }, { status: 500 });
    }
}