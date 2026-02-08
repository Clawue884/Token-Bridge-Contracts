import { task } from "hardhat/config";

task("deploy:guardian", "Deploy BridgeGuardian")
  .addParam("admin", "Admin address")
  .setAction(async ({ admin }, hre) => {
    const Guardian = await hre.ethers.getContractFactory("BridgeGuardian");
    const guardian = await Guardian.deploy(admin);
    await guardian.waitForDeployment();
    console.log("BridgeGuardian deployed to:", await guardian.getAddress());
  });
