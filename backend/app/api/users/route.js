import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
  try {
    // Using the Supabase Client instead of direct SQL
    const { data, error } = await supabase.from('users').select('*');
    
    if (error) {
      throw error;
    }

    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: "Supabase connection failed", details: error.message },
      { status: 500 }
    );
  }
}
