import { ethers } from "ethers";
import client from "prom-client";
import * as dotenv from "dotenv";
dotenv.config();

const RPC = process.env.RPC_URL!;
const GUARDIAN = process.env.GUARDIAN_ADDRESS!;
const PORT = 9100;

const abi = [
  "event BridgeStatus(address indexed token, uint256 used, uint256 max, string status)",
];

const register = new client.Registry();
const bridgeUsed = new client.Gauge({ name: "bridge_used", help: "Bridge used volume", labelNames: ["token"] });
const bridgeMax = new client.Gauge({ name: "bridge_max", help: "Bridge max per hour", labelNames: ["token"] });

register.registerMetric(bridgeUsed);
register.registerMetric(bridgeMax);

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const guardian = new ethers.Contract(GUARDIAN, abi, provider);

  guardian.on("BridgeStatus", (token, used, max) => {
    bridgeUsed.labels(token).set(Number(used));
    bridgeMax.labels(token).set(Number(max));
  });

  require("http").createServer(async (_, res) => {
    res.end(await register.metrics());
  }).listen(PORT);

  console.log(`📊 Metrics on http://localhost:${PORT}/metrics`);
}

main().catch(console.error);
