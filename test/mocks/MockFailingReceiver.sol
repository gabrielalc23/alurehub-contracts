// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

contract MockFailingReceiver {
    receive() external payable {
        revert NativeReceiveRejected();
    }

    error NativeReceiveRejected();
}
