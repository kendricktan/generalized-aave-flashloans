const ethers = require("ethers");

const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
const wallet = new ethers.Wallet(
  "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
  provider
);

const {
  dsProxyFactoryAddress,
  proxyLogicAddress,
  flashloanWrapperAddress
} = require("../build/DeployedAddresses.json");

const dsProxyFactoryDef = require("../build/contracts/DSProxyFactory.json");
const dsProxyDef = require("../build/contracts/DSProxy.json");
const proxyLogicDef = require("../build/contracts/ProxyLogic.json");
const flashloanWrapperDef = require("../build/contracts/FlashLoanWrapper.json");

const dsProxyFactoryContract = new ethers.Contract(
  dsProxyFactoryAddress,
  dsProxyFactoryDef.abi,
  wallet
);

const proxyLogicContract = new ethers.Contract(
  proxyLogicAddress,
  proxyLogicDef.abi,
  wallet
);

const IFlashloanWrapper = new ethers.utils.Interface(flashloanWrapperDef.abi);
const IProxyLogicWrapper = new ethers.utils.Interface(proxyLogicDef.abi);

describe("Generalized Flash Loans", () => {
  it("Testing flashloan wrapper execution", async () => {
    await dsProxyFactoryContract.build({ gasLimit: 4000000 });
    const dsProxyAddress = await dsProxyFactoryContract.proxies(wallet.address);

    const dsProxyContract = new ethers.Contract(
      dsProxyAddress,
      dsProxyDef.abi,
      wallet
    );

    // Transfers 0.1 ETH to dsProxyContract so it'll have enough funds to repay
    // Aave loan
    // Note: We're only doing this because we're not doing something crazy with
    //       the flashloans as as borrowing money / liquidating people and need
    //       the extra 0.1 ETH to repay the fees
    await wallet.sendTransaction({
      to: dsProxyContract.address,
      value: ethers.utils.parseEther("0.1")
    });

    // Constructs the flashloan encoding data

    //   struct MyCustomData {
    //     address flashloanWrapperAddress;
    //     uint a; // Random data
    //   }
    const myCustomData = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint"],
      [flashloanWrapperAddress, "10"]
    );

    const executeOperationCalldataParams = IProxyLogicWrapper.functions.flashLoanPostLoan.encode(
      [
        "0x0000000000000000000000000000000000000000",
        0,
        0, // Doesn't matter since flashloan wrapper will reencode the right data
        myCustomData
      ]
    );

    const flashloanCalldata = IProxyLogicWrapper
      .functions
      .flashLoan
      .encode([
        ethers.utils.parseEther("1.0"),
        dsProxyAddress,
        flashloanWrapperAddress,
        proxyLogicAddress,
        executeOperationCalldataParams
      ])

    
    // Tells our proxy to execute the flashloan
    await dsProxyContract.execute(
      proxyLogicAddress,
      flashloanCalldata,
      {
        gasLimit: 4000000
      }
    )
  });
});
