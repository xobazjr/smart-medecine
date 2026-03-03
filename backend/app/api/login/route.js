// base template by gemini

import { NextResponse } from 'next/server';
import sql from '../../../lib/db'; // Adjust this path depending on where db.js is located
import bcrypt from 'bcryptjs';

export async function POST(request) {
    try {
        const { username, password } = await request.json();

        if (!username || !password) {
            return NextResponse.json(
                { error: "Username and password are required" },
                { status: 400 }
            );
        }

        // 1. Raw SQL query using postgres.js tagged template literal
        // The library automatically parameterizes ${username} to prevent SQL injection!
        const users = await sql`SELECT * FROM users WHERE username = ${username} LIMIT 1`;

        const user = users[0];

        if (!user) {
            return NextResponse.json(
                { error: "Invalid username or password" },
                { status: 401 }
            );
        }

        
        // 2. Compare the provided password with the stored hash
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);

        if (!isPasswordValid) {
            return NextResponse.json(
                { error: "Invalid username or password" },
                { status: 401 }
            );
        }

        // 3. Success! Return user data (excluding the password hash)
        return NextResponse.json({
            message: "Login successful",
            user: {
                user_id: user.user_id,
                username: user.username,
                role: user.role,
                tel: user.tel
            }
        });

    } catch (error) {
        console.error("Login Error:", error);
        return NextResponse.json(
            { error: "Internal server error", details: error.message },
            { status: 500 }
        );
    }
}