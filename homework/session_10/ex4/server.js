
const express = require("express");
const { Pool } = require("pg");

const app = express();
const PORT = 3000;

const pool = new Pool({
  host: process.env.DB_HOST || "db-server",
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || "appdb",
  user: process.env.DB_USER || "appuser",
  password: process.env.DB_PASSWORD || "apppass"
});

app.get("/", (req, res) => {
  res.json({
    message: "Backend API is running",
    databaseHost: process.env.DB_HOST || "db-server"
  });
});

app.get("/api/health", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT current_database() AS database, NOW() AS server_time"
    );

    res.json({
      status: "UP",
      database: result.rows[0].database,
      serverTime: result.rows[0].server_time
    });
  } catch (error) {
    res.status(500).json({
      status: "DOWN",
      error: error.message
    });
  }
});

app.get("/api/records", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, content FROM persistence_test ORDER BY id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Backend listening on port ${PORT}`);
  console.log(`Database hostname: ${process.env.DB_HOST || "db-server"}`);
});
