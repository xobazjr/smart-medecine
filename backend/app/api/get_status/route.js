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
        const diffInSeconds = Math.floor((now - ts) / 1000);

        // --- 1. Basic Formatting ---
        const dateStr = ts.toISOString().split('T')[0];
        const timeStr = ts.toTimeString().split(' ')[0];

        // --- 2. Expanded Last Seen Logic ---
        let lastSeen = "";

        const minutes = Math.floor(diffInSeconds / 60);
        const hours   = Math.floor(diffInSeconds / 3600);
        const days    = Math.floor(diffInSeconds / 86400);
        const weeks   = Math.floor(diffInSeconds / 604800);
        const months  = Math.floor(diffInSeconds / 2592000); // approx 30 days
        const years   = Math.floor(diffInSeconds / 31536000); // approx 365 days

        if (diffInSeconds < 60) {
            lastSeen = `${diffInSeconds} seconds ago`;
        } else if (minutes < 60) {
            lastSeen = `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
        } else if (hours < 24) {
            lastSeen = `${hours} hour${hours > 1 ? 's' : ''} ago`;
        } else if (days < 7) {
            lastSeen = `${days} day${days > 1 ? 's' : ''} ago`;
        } else if (weeks < 4) {
            lastSeen = `${weeks} week${weeks > 1 ? 's' : ''} ago`;
        } else if (months < 12) {
            lastSeen = `${months} month${months > 1 ? 's' : ''} ago`;
        } else {
            lastSeen = `${years} year${years > 1 ? 's' : ''} ago`;
        }

        return NextResponse.json({
            timestamp: ts,
            date: dateStr,
            time: timeStr,
            datetime: `${dateStr} ${timeStr}`,
            last_seen: lastSeen
        });

    } catch (e) {
        return NextResponse.json({ status: 500, error: e.message }, { status: 500 });
    }
}