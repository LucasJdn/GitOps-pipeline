const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || '1.0.0';
const ENVIRONMENT = process.env.ENVIRONMENT || 'production';

app.use(express.json());

// Root welcome & metadata endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'GitOps Pipeline: GitHub Actions + Terraform + ECS Fargate (Blue/Green)',
    environment: ENVIRONMENT,
    version: APP_VERSION,
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
  });
});

// Health check endpoint for ALB target groups & container health
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
    memory_usage: process.memoryUsage(),
  });
});

// Diagnostic endpoint to view container environment info
app.get('/info', (req, res) => {
  res.status(200).json({
    app_version: APP_VERSION,
    environment: ENVIRONMENT,
    node_version: process.version,
    platform: process.platform,
    pid: process.pid,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.originalUrl,
  });
});

// Graceful shutdown handling
const startServer = () => {
  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`[${new Date().toISOString()}] Server running on port ${PORT} (env: ${ENVIRONMENT}, version: ${APP_VERSION})`);
  });

  const handleShutdown = (signal) => {
    console.log(`[${new Date().toISOString()}] Received ${signal}. Gracefully closing HTTP server...`);
    server.close(() => {
      console.log(`[${new Date().toISOString()}] HTTP server closed. Exiting process.`);
      process.exit(0);
    });

    // Force shutdown after 10 seconds timeout if open connections stall
    setTimeout(() => {
      console.error(`[${new Date().toISOString()}] Forcefully shutting down after timeout.`);
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => handleShutdown('SIGTERM'));
  process.on('SIGINT', () => handleShutdown('SIGINT'));

  return server;
};

// Only bind the port when executed directly (`node server.js`), not when imported by tests
if (require.main === module) {
  startServer();
}

module.exports = app;
