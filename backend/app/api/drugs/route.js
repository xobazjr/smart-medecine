import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
  try {
    // Fetch all records from the 'drugs' table
    const { data, error } = await supabase.from('drugs').select('*');
    
    if (error) {
      throw error;
    }

    return NextResponse.json(data);
  } catch (error) {
    console.error("Supabase Error (Drugs):", error);
    return NextResponse.json(
      { error: "Failed to fetch drugs from Supabase", details: error.message },
      { status: 500 }
    );
  }
}
