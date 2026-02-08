import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

const RPC = process.env.RPC_URL!;
const GUARDIAN = process.env.GUARDIAN_ADDRESS!;
const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK!;

const abi = [
  "event BridgeStatus(address indexed token, uint256 used, uint256 max, string status)",
  "event TransferChecked(address indexed token, uint256 amount, bool allowed)"
];

async function sendDiscord(msg: string) {
  await fetch(DISCORD_WEBHOOK, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ content: msg }),
  });
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const guardian = new ethers.Contract(GUARDIAN, abi, provider);

  console.log("Watcher running...");

  guardian.on("BridgeStatus", async (token, used, max, status) => {
    const msg = `🛡️ Bridge Status\nToken: ${token}\nUsed: ${used}/${max}\nStatus: ${status}`;
    console.log(msg);
    if (status !== "HEALTHY") await sendDiscord(msg);
  });

  guardian.on("TransferChecked", (token, amount, allowed) => {
    console.log(`🔄 Transfer ${allowed ? "OK" : "BLOCKED"} | ${token} | ${amount}`);
  });
}

main().catch(console.error);
