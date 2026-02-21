import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not defined in your .env.local file');
}

const sql = postgres(connectionString);

export default sql;