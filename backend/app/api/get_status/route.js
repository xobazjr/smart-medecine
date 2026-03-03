import { NextResponse } from 'next/server';
import sql from '../../../lib/db';

export async function GET(req) {
    try {
        const query_status = await sql`SELECT * FROM board_status WHERE name = 'esp8266_xbjr' LIMIT 1`;

        if (query_status.length === 0) {
            return NextResponse.json({ error: "Device not found" }, { status: 404 });
        }

        // 1. Ensure we treat the DB timestamp as a proper Date object
        const ts = new Date(query_status[0].timestamp);
        const now = new Date();
        const diffInSeconds = Math.floor((now - ts) / 1000);

        // 2. Use 'toLocaleString' to force Bangkok (UTC+7) formatting
        // This prevents the 'negative' offset issue
        const options = { timeZone: 'Asia/Bangkok', hour12: false };

        const dateStr = ts.toLocaleDateString('en-CA', options); // YYYY-MM-DD
        const timeStr = ts.toLocaleTimeString('en-GB', options); // HH:MM:SS
        const datetimeStr = `${dateStr} ${timeStr}`;

        // 3. Human-readable Logic (remains the same)
        let lastSeen = "";
        const absDiff = Math.abs(diffInSeconds); // Use Absolute value as a safety net

        if (diffInSeconds < 0 && absDiff < 30) {
            lastSeen = "just now"; // Handles tiny clock drifts
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
            timestamp: ts,
            date: dateStr,
            time: timeStr,
            datetime: datetimeStr,
            last_seen: lastSeen
        });

    } catch (e) {
        return NextResponse.json({ status: 500, error: e.message }, { status: 500 });
    }
}