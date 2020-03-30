pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProxyLogic {
    address constant ETHADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() public {}
    function() external payable {}

    struct MyCustomData {
        address flashloanWrapperAddress;
        uint a;
    }

    function executeFlashLoanLogic(
        address _reserve,
        uint _amount,
        uint _fee,
        bytes calldata _data
    ) external {
        MyCustomData memory myCusData = abi.decode(_data, (MyCustomData));

        address flashloanWrapperAddress = myCusData.flashloanWrapperAddress;
        uint repayAmount = _amount + _fee;

        // Do you custom logic here
        if(_reserve == ETHADDRESS) {
            flashloanWrapperAddress.call.value(repayAmount)("");
        } else {
            IERC20(_reserve).transfer(flashloanWrapperAddress, repayAmount);
        }
    }
}