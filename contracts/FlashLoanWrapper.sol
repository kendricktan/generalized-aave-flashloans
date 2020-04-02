pragma solidity 0.5.16;

import "./lib/FlashLoanReceiverBase.sol";
import "./lib/BytesLibLite.sol";
import "./Proxy.sol";

contract FlashLoanWrapper is FlashLoanReceiverBase, BytesLibLite {
    constructor() public {}

    function() external payable {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {
        // _params encoding:

        // Injects new data for ProxyLogic, and extracts out valid data to call,
        // and reinjects relevant data (_reserve, _amount, _fee)
        /* (
                address - Proxy Address            | start: 0;   (20 bytes)
                address - Proxy.execute's _target  | start: 20;  (20 bytes)
                bytes   - Function sig             | start: 40;  (4 bytes)
                address - _reserve                 | start: 44;  (32 bytes)
                uint    - _amount                  | start: 76;  (32 bytes)
                uint    - _fee                     | start: 108; (32 bytes)
                bytes   - _data                    | start: 140; (dynamic length)
            )

            i.e. (in ProxyLogic.sol)

            function executeFlashLoanLogic(
                address _reserve,
                uint _amount,
                uint _fee,
                bytes calldata _data
            ) { ... }
        */

        // Proxy address which we want to call
        address payable proxyAddress = address(uint160(bytesToAddress(_params, 0)));

        // Contract address where proxy will execute on
        address _target = bytesToAddress(_params, 20);

        // Function signature for the contract address
        // where proxy will execute on
        bytes memory fSig = slice(_params, 40, 4);

        // Data to supply with the function signature
        bytes memory _data = sliceToEnd(_params, 140);

        bytes memory _newData = abi.encodePacked(
            fSig,
            abi.encode(_reserve),
            abi.encode(_amount),
            abi.encode(_fee),
            _data
        );

        // Sends the funds to the proxyAddress
        if(_reserve == ETHADDRESS) {
            //solium-disable-next-line
            proxyAddress.call.value(_amount)("");
        } else {
            IERC20(_reserve).transfer(proxyAddress, _amount);
        }

        // Assume that once this is completed
        // we will get enough funds to repay Aave
        DSProxy(proxyAddress).execute(_target, _newData);

        // Transfer funds back to Aave
        transferFundsBackToPoolInternal(_reserve, _amount + _fee);
    }
}