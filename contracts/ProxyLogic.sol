pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./Proxy.sol";

import "./lib/Guard.sol";
import "./lib/FlashLoanReceiverBase.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ProxyLogic {
    address constant ETHADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant AaveEthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant AaveLendingPoolAddressProviderAddress = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    constructor() public {}

    function() external payable {}

    struct MyCustomData {
        address payable flashloanWrapperAddress;
        uint256 a;
    }

    function _proxyGuardPermit(address payable proxyAddress, address src)
        internal
    {
        address g = address(DSProxy(proxyAddress).authority());

        DSGuard(g).permit(
            bytes32(bytes20(address(src))),
            DSGuard(g).ANY(),
            DSGuard(g).ANY()
        );
    }

    function _proxyGuardForbid(address payable proxyAddress, address src)
        internal
    {
        address g = address(DSProxy(proxyAddress).authority());

        DSGuard(g).forbid(
            bytes32(bytes20(address(src))),
            DSGuard(g).ANY(),
            DSGuard(g).ANY()
        );
    }

    // This function is triggered AFTER Aave has loaned us $,
    // which having DSProxy as the storage
    // (i.e. the contract code is executed as DSProxy, and not as ProxyLogic)
    function flashLoanPostLoan(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {
        MyCustomData memory d = abi.decode(_params, (MyCustomData));

        // INSERT YOUR LOGIC HERE:
        // Do your arbitrage here / finance VM building blocks here

        // Once you're done you'll need to send the funds back to the wrapper,
        // as the wrapper is responsible for paying the fees back.
        // Otherwise the whole Tx fails
        //solium-disable-next-line
        d.flashloanWrapperAddress.call.value(_amount)("");
    }

    // User tells proxy to execute this function
    function flashLoan(
        uint256 flashloanEthAmount,
        address payable dsProxyAddress,
        address flashloanWrapperAddress,
        address proxyLogicAddress,
        bytes calldata executeOperationCalldataParams
    ) external {
        // Injects proxy and target address into calldataParams
        // See FlashLoanWrapper.sol for more info
        bytes memory addressAndExecuteOperationCalldataParams = abi
            .encodePacked(
            abi.encodePacked(dsProxyAddress),
            abi.encodePacked(proxyLogicAddress),
            executeOperationCalldataParams
        );

        // Approve flashloan wrapper to call proxy
        _proxyGuardPermit(dsProxyAddress, flashloanWrapperAddress);

        // Flashloan to flashloanWrapperAddress
        // This triggers `executeOperation` in flashloanWrapperAddress
        // which then calls DSProxy to execute the target address using the given method
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(AaveLendingPoolAddressProviderAddress)
                .getLendingPool()
        );
        lendingPool.flashLoan(
            flashloanWrapperAddress,
            AaveEthAddress,
            flashloanEthAmount,
            addressAndExecuteOperationCalldataParams
        );

        // Forbids lendingPool to call proxy
        _proxyGuardForbid(dsProxyAddress, flashloanWrapperAddress);
    }
}
