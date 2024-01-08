const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // deploying the NFT Contract
  const nftContract = await hre.ethers.deployContract("CryptoTards");
  await nftContract.waitForDeployment();
  console.log("Nft Contract Deployed to", nftContract.target);

  // deploying the fake NFT marketplace
  const fakeNFTMarketplace = await hre.ethers.deployContract(
    "FakeNFTMarketplace"
  );
  await fakeNFTMarketplace.waitForDeployment();
  console.log("Fake NFT Market Place Deployed to", fakeNFTMarketplace.target);

  // deploying the DAO Smartcontract
  const amount = hre.ethers.parseEther("0.3");
  const daoContract = await hre.ethers.deployContract(
    "CryptoTardsDAO",
    [fakeNFTMarketplace.target, nftContract.target],
    { value: amount }
  );
  await daoContract.waitForDeployment();
  console.log("DAO Contract Deployed to", daoContract.target);

  // Sleep for 30 secs
  await sleep(30 * 1000);

  // Contract verification with etherscan
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });

  // Verify the Fake Marketplace Contract
  await hre.run("verify:verify", {
    address: fakeNFTMarketplace.target,
    constructorArguments: [],
  });

  // Verify the DAO Contract
  await hre.run("verify:verify", {
    address: daoContract.target,
    constructorArguments: [fakeNFTMarketplace.target, nftContract.target],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
