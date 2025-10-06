// ============================================================================
// homepage/wol-server.js - Wake-on-LAN API for Homepage
// ============================================================================

// Simple Express server to handle WOL requests from Homepage
// This should be added as a separate container or run on the Pi

const express = require("express");
const { exec } = require("child_process");
const app = express();

const DESKTOP_MAC = "XX:XX:XX:XX:XX:XX"; // Replace with your desktop's MAC address
const PORT = 3001;

app.use(express.json());

app.post("/api/wol/desktop", (req, res) => {
  exec(`wakeonlan ${DESKTOP_MAC}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error}`);
      return res.status(500).json({ error: "Failed to send WOL packet" });
    }
    console.log(`WOL packet sent to ${DESKTOP_MAC}`);
    res.json({ success: true, message: "Wake-on-LAN packet sent" });
  });
});

// Check if desktop is online
app.get("/api/status/desktop", (req, res) => {
  exec("ping -c 1 -W 1 10.0.0.2", (error) => {
    res.json({ online: !error });
  });
});

app.listen(PORT, () => {
  console.log(`WOL API server running on port ${PORT}`);
});
