import { Consumer } from "kafkajs";

const HEARTBEAT_CHECK_INTERVAL = 40000;

export function heartbeat_or_die(consumer: Consumer) {
  let lastHeartbeat = new Date();

  // listen to heartbeat
  consumer.on("consumer.heartbeat", () => {
    lastHeartbeat = new Date();
  });

  // start heartbeat check, if we detect that we do not have heartbeat, restart.
  function startHeartbeatCheck() {
    setInterval(async () => {
      const now = new Date();
      if (lastHeartbeat.getTime() < now.getTime() - HEARTBEAT_CHECK_INTERVAL) {
        console.error(new Error(`Last heartbeat was at ${lastHeartbeat}`));
        process.exit(1);
      }
    }, HEARTBEAT_CHECK_INTERVAL);
  }
  startHeartbeatCheck();
}
