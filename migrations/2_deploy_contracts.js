 
const fs = require("fs");
const path = require("path");

const DSProxyFactory = artifacts.require("DSProxyFactory");
const ProxyLogic = artifacts.require("ProxyLogic");
const FlashLoanWrapper = artifacts.require("FlashLoanWrapper");

module.exports = async deployer => {
    await deployer.deploy(DSProxyFactory)
    await deployer.deploy(ProxyLogic)
    await deployer.deploy(FlashLoanWrapper)

    // Saves to a file if needed
    const data = JSON.stringify({
        dsProxyFactoryAddress: DSProxyFactory.address,
        proxyLogicAddress: ProxyLogic.address,
        flashloanWrapperAddress: FlashLoanWrapper.address
    });

    const buildDir = path.resolve(__dirname, "../build");
    if (!fs.existsSync(buildDir)) {
        fs.mkdirSync(buildDir);
    }
    fs.writeFileSync(path.resolve(buildDir, "DeployedAddresses.json"), data);
};