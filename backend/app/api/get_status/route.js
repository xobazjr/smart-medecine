import { NextResponse } from 'next/server';
import sql from '../../../lib/db';

export async function GET(req) {
    try {
        const query_status = await sql`SELECT * FROM board_status WHERE name = 'esp8266_xbjr' LIMIT 1`;

        if (query_status.length === 0) {
            return NextResponse.json({ error: "Device not found" }, { status: 404 });
        }

        const ts = new Date(query_status[0].timestamp);
        const now = new Date();

        // --- 1. Fix the "Negative" Math ---
        // We get the difference in seconds.
        // If it's negative, it's usually because of server clock drift or TZ mismatch.
        let diffInSeconds = Math.floor((now - ts) / 1000);

        // --- 2. Force Bangkok Formatting (UTC+7) ---
        // This ensures the strings for Date and Time match Thailand, not the Vercel Server location.
        const tz = 'Asia/Bangkok';
        const dateStr = ts.toLocaleDateString('en-CA', { timeZone: tz }); // YYYY-MM-DD
        const timeStr = ts.toLocaleTimeString('en-GB', { timeZone: tz, hour12: false }); // HH:MM:SS

        // --- 3. Robust Last Seen Logic ---
        let lastSeen = "";

        // If diff is negative but small (under 1 min), the clock is just slightly out of sync
        if (diffInSeconds < 0 && Math.abs(diffInSeconds) < 60) {
            lastSeen = "just now";
        } else if (diffInSeconds < 60) {
            lastSeen = `${Math.max(0, diffInSeconds)} seconds ago`;
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
            timestamp: ts, // Raw ISO
            date: dateStr,
            time: timeStr,
            datetime: `${dateStr} ${timeStr}`,
            last_seen: lastSeen
        });

    } catch (e) {
        return NextResponse.json({ status: 500, error: e.message }, { status: 500 });
    }
}