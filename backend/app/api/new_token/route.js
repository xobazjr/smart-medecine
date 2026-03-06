import { NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';

export async function POST(req) {
    try {
        // 1. Extract the token from the Authorization header
        const authHeader = req.headers.get('authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return NextResponse.json(
                { error: 'Unauthorized: Missing or invalid token' },
                { status: 401 }
            );
        }

        const oldToken = authHeader.split(' ')[1];

        // 2. Verify the old token
        // We need to verify it to ensure it's a valid token issued by us, even if it's about to expire.
        // However, if it is ALREADY expired, jwt.verify will throw an error.
        // If you want to allow refreshing expired tokens, you'd need to ignore expiration here,
        // but that is less secure. Standard practice is to refresh BEFORE it expires.
        let decoded;
        try {
            decoded = jwt.verify(oldToken, process.env.JWT_SECRET || 'default_secret_key');
        } catch (err) {
            return NextResponse.json(
                { error: 'Unauthorized: Invalid or expired token' },
                { status: 401 }
            );
        }

        // 3. Generate a NEW token with a fresh expiration
        // We use the data from the old token (excluding 'iat' and 'exp' which are added by sign)
        const newToken = jwt.sign(
            { 
                userId: decoded.userId, 
                username: decoded.username, 
                role: decoded.role 
            },
            process.env.JWT_SECRET || 'default_secret_key',
            { expiresIn: '30d' } // Reset the clock to 30 days
        );

        // 4. Return the new token
        return NextResponse.json({
            message: "Token refreshed successfully",
            token: newToken
        });

    } catch (error) {
        console.error("Token Refresh Error:", error);
        return NextResponse.json(
            { error: "Internal server error", details: error.message },
            { status: 500 }
        );
    }
}